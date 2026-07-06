--------------------------------------------------------------------------------
-- Services/AlchemyRecipeService.lua
-- Сервис для работы с рецептами алхимии.
-- Отвечает за кэширование списка всех доступных рецептов, фильтрацию по
-- имеющимся компонентам и подсчет потенциально возможных рецептов с учетом
-- физически положенных в барабаны предметов.
--------------------------------------------------------------------------------

Class( "AlchemyRecipeService", {
	_state = nil,               -- Ссылка на глобальный объект состояния аддона (AlchemyState).
	_componentNamesCache = {},  -- Кэш имен компонентов для оптимизации обращений к API.
	                            -- Структура: { [ComponentId (userdata)] = "ИмяКомпонента (string)" }.
} )

--------------------------------------------------------------------------------
--- Инициализация сервиса.
--- @param state table AlchemyState
--------------------------------------------------------------------------------
function AlchemyRecipeService:Init( state )
	self._state = state
end

--------------------------------------------------------------------------------
--- Получить строковое имя компонента по его ID.
--- Использует внутренний кэш для минимизации обращений к API.
--- @param componentId userdata (ComponentPropertyId/ResourceId).
--- @return nil | string name выводит имя
--------------------------------------------------------------------------------
function AlchemyRecipeService:GetComponentName( componentId )
	-- Если имя уже запрашивалось, возвращаем его сразу
	if self._componentNamesCache[ componentId ] then
		return self._componentNamesCache[ componentId ]
	end
	
	-- componentInfo: table or nil. Содержит поля: id, name (WString), description (WString), image.
	local componentInfo = avatar.GetComponentInfo( componentId )
	
	if componentInfo then
		local name = userMods.FromWString( componentInfo.name )
		
		-- Сохраняем в кэш
		self._componentNamesCache[ componentId ] = name
		return name
	end
	
	return nil
end

--------------------------------------------------------------------------------
--- Создать и закешировать полный список всех доступных игроку рецептов алхимии.
--- Выполняется один раз при открытии окна алхимии или при изменении списка рецептов.
--------------------------------------------------------------------------------
function AlchemyRecipeService:CreateRecipeCache()
	-- Если кэш уже создан
	if self._state.recipeCache ~= nil then
		return
	end
	
	self._state.recipeCache = {}
	
	-- alchemyInfo: table. Содержит drumsCount, correctionCount, recipes (массив RecipeId) и т.д.
	local alchemyInfo = avatar.GetAlchemyInfo()
	
	-- Сохраняем актуальное количество слотов (барабанов) в состояние
	self._state.drumsCount = alchemyInfo.drumsCount

	-- Проходим по всем доступным игроку рецептам
	-- recipeId: userdata (RecipeId) - идентификатор ресурса рецепта
	for _, recipeId in pairs( alchemyInfo.recipes ) do
		-- recipeInfo: table. Содержит name (WString), score (int), components (массив ComponentId) и т.д.
		local recipeInfo = avatar.GetRecipeInfo( recipeId )
		
		if recipeInfo then
			local recipe = {
				componentsCount = 0,                              -- Общее количество компонентов, требуемых рецептом.
				name = userMods.FromWString( recipeInfo.name ),   -- Локализованное имя зелья/рецепта.
				score = recipeInfo.score,                         -- Необходимый уровень умения для крафта.
				requiredComponents = {},                          -- Хеш-таблица требуемых компонентов: { ["Имя"] = кол-во }.
			}

			-- Разбираем массив компонентов рецепта
			for _, componentId in pairs( recipeInfo.components ) do
				local componentName = self:GetComponentName( componentId )
				
				if componentName then
					-- Увеличиваем счетчик требуемого количества данного компонента
					recipe.requiredComponents[ componentName ] = ( recipe.requiredComponents[ componentName ] or 0 ) + 1
					-- Увеличиваем общий счетчик компонентов в рецепте
					recipe.componentsCount = recipe.componentsCount + 1
				end
			end

			-- Добавляем готовую структуру рецепта в общий кэш
			table.insert( self._state.recipeCache, recipe )
		end
	end
end

--------------------------------------------------------------------------------
--- Проверить, соответствуют ли доступные компоненты требованиям конкретного рецепта.
--- @param recipe table структура рецепта из кэша (содержит componentsCount, requiredComponents).
--- @param availableComponents table хеш-таблица доступных компонентов { ["Имя"] = кол-во }.
--- @param filledSlotsCount number количество заполненных слотов (барабанов) в ступке.
--- @return boolean
--------------------------------------------------------------------------------
function AlchemyRecipeService:IsRecipeMatch( recipe, availableComponents, filledSlotsCount )
	-- Количество заполненных слотов должно совпадать с требуемым кол-вом компонентов
	if recipe.componentsCount ~= filledSlotsCount then
		return false
	end
	
	-- Проверяем наличие каждого требуемого компонента
	for componentName, neededCount in pairs( recipe.requiredComponents ) do
		-- Если доступного компонента меньше, чем требуется
		if ( availableComponents[ componentName ] or 0 ) < neededCount then
			return false
		end
	end
	
	return true
end

--------------------------------------------------------------------------------
--- Отфильтровать глобальный кэш рецептов, оставляя только те, которым соответствуют
--- уникальные компоненты, лежащие в барабанах (без учета сдвигов/коррекций).
--- @param availableComponents table { ["ИмяКомпонента"] = кол-во_слотов_с_этим_компонентом }.
--- @param filledDrumsCount number общее количество барабанов, в которые положены предметы.
--- @return integer count кол-во рецептов с подходящими компонентами
--------------------------------------------------------------------------------
function AlchemyRecipeService:FilterByComponents( availableComponents, filledDrumsCount )
	-- Гарантируем, что кэш рецептов создан
	self:CreateRecipeCache()
	
	self._state.filteredRecipes = {}
	local count = 0
	
	for _, recipe in pairs( self._state.recipeCache ) do
		if self:IsRecipeMatch( recipe, availableComponents, filledDrumsCount ) then
			table.insert( self._state.filteredRecipes, recipe )
			count = count + 1
		end
	end
	
	return count
end

--------------------------------------------------------------------------------
--- Подсчитать количество потенциально возможных рецептов на основе того, какие
--- предметы физически положены в слоты (без учета сдвигов).
--- @return integer potentialCount количество возможных рецептов
--- @return integer filledDrumsCount количество заполненных слотов
--------------------------------------------------------------------------------
function AlchemyRecipeService:CountPotential()
	-- Гарантируем, что кэш рецептов создан
	self:CreateRecipeCache()
	
	local potentialCount = 0
	local filledDrumsCount = 0
	local availableComponents = {}

	-- Проходим по всем слотам (барабанам). Нумерация в API начинается с 0.
	for drumIdx = 1, self._state.drumsCount do
		-- drumInfo: table or nil. Содержит itemId, components (массив ComponentId), position и др.
		local drumInfo = avatar.GetAlchemyDrumInfo( drumIdx - 1 )
		
		-- Проверяем, что барабан существует и в него положен предмет
		if drumInfo and drumInfo.itemId ~= nil then
			filledDrumsCount = filledDrumsCount + 1

			-- Если в барабане есть компоненты (предмет не пустой)
			if drumInfo.components then
				-- Хеш-таблица для учета УНИКАЛЬНЫХ компонентов внутри ОДНОГО барабана.
				local seenInDrum = {}
				
				-- Собираем все уникальные компоненты этого барабана
				for _, componentId in pairs( drumInfo.components ) do
					local componentName = self:GetComponentName( componentId )
					if componentName then
						seenInDrum[ componentName ] = true
					end
				end
				
				-- Каждый уникальный компонент в барабане добавляет +1 к счетчику доступных компонентов
				for componentName, _ in pairs( seenInDrum ) do
					availableComponents[ componentName ] = ( availableComponents[ componentName ] or 0 ) + 1
				end
			end
		end
	end

	-- Проверяем, сколько рецептов из кэша удовлетворяют собранному набору
	for _, recipe in pairs( self._state.recipeCache ) do
		if self:IsRecipeMatch( recipe, availableComponents, filledDrumsCount ) then
			potentialCount = potentialCount + 1
		end
	end

	-- Возвращаем количество возможных рецептов и количество заполненных слотов
	return potentialCount, filledDrumsCount
end