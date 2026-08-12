--------------------------------------------------------------------------------
-- Services/AlchemyRecipeService.lua
-- Сервис для работы с рецептами алхимии.
-- Отвечает за кэширование списка всех доступных рецептов, фильтрацию по
-- имеющимся компонентам и подсчет возможных рецептов.
--------------------------------------------------------------------------------

Class( "AlchemyRecipeService", {
	_state = nil,               -- AlchemyState.
	_componentNamesCache = nil,  -- Кэш имен компонентов для оптимизации.
	                            -- Структура: { [ComponentId (userdata)] = "ИмяКомпонента (string)" }.
} )

--------------------------------------------------------------------------------
--- Инициализация сервиса.
--- @param state table AlchemyState
--------------------------------------------------------------------------------
function AlchemyRecipeService:Init( state )
	self._state = state
	self._componentNamesCache = {}
end

--------------------------------------------------------------------------------
--- Получить строковое имя компонента по его ID.
--- Использует внутренний кэш.
--- @param componentId userdata (ComponentPropertyId/ResourceId).
--- @return nil | string name выводит имя
--------------------------------------------------------------------------------
function AlchemyRecipeService:GetComponentName( componentId )
	-- Если имя уже запрашивалось, возвращает его сразу
	if self._componentNamesCache[ componentId ] then
		return self._componentNamesCache[ componentId ]
	end
	
	-- componentInfo: table or nil. Содержит поля: id, name (WString), description (WString), image.
	local componentInfo = avatar.GetComponentInfo( componentId )
	
	if componentInfo then
		local name = userMods.FromWString( componentInfo.name )
		
		-- Сохранить в кэш
		self._componentNamesCache[ componentId ] = name
		return name
	end
	
	return nil
end

--------------------------------------------------------------------------------
--- Создать и сохранить в кэш полный список всех доступных рецептов алхимии.
--- Выполняется один раз при открытии окна алхимии или при изменении списка рецептов.
--------------------------------------------------------------------------------
function AlchemyRecipeService:CreateRecipeCache()
	-- Если кэш уже создан
	if self._state.recipeCache ~= nil then
		return
	end
	
	--[[
	{
		{
			"componentsCount" => 5,
			"name" => "Сильное зелье исцеления",
			"requiredComponents" => {
				"Время" => 2
				"Исцеление" => 2
				"Оглушение" => 1
			},
			"score" => 41
		},
		...
	}
	]]
	self._state.recipeCache = {}
	
	-- alchemyInfo: table = { drumsCount, correctionCount, recipes (массив RecipeId) и т.д }.
	local alchemyInfo = avatar.GetAlchemyInfo()
	
	-- Сохранить актуальное количество слотов (барабанов) в состояние
	self._state.drumsCount = alchemyInfo.drumsCount

	-- Проходит по всем доступным рецептам
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

			-- Разбирает массив компонентов рецепта
			for _, componentId in pairs( recipeInfo.components ) do
				local componentName = self:GetComponentName( componentId )
				
				if componentName then
					-- Увеличивает счетчик требуемого количества данного компонента
					recipe.requiredComponents[ componentName ] = ( recipe.requiredComponents[ componentName ] or 0 ) + 1
					-- Увеличивает общий счетчик компонентов в рецепте
					recipe.componentsCount = recipe.componentsCount + 1
				end
			end

			-- Добавляет готовую структуру рецепта в общий кэш
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
	
	-- Проверяет наличие каждого требуемого компонента
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
	-- Проверить кэш.
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
--- Подсчитать количество возможных рецептов на основе того, какие
--- предметы положены в слоты (без учета сдвигов).
--- @return integer potentialCount количество возможных рецептов
--- @return integer filledDrumsCount количество заполненных слотов
--------------------------------------------------------------------------------
function AlchemyRecipeService:CountPotential()
	-- Проверить кэш.
	self:CreateRecipeCache()
	
	local potentialCount = 0
	local filledDrumsCount = 0
	local availableComponents = {}

	-- Проходит по всем слотам (барабанам).
	for drumIdx = 1, self._state.drumsCount do
		-- Нумерация в GetAlchemyDrumInfo начинается с 0.
		-- drumInfo: table or nil. Содержит itemId, components (массив ComponentId), position и др.
		local drumInfo = avatar.GetAlchemyDrumInfo( drumIdx - 1 )
		
		-- Проверяет, что барабан существует и в него положен предмет
		if drumInfo and drumInfo.itemId ~= nil then
			filledDrumsCount = filledDrumsCount + 1

			-- Если в слотах есть компоненты
			if drumInfo.components then
				-- Хеш-таблица для учета УНИКАЛЬНЫХ компонентов внутри (ОДНОГО) барабана.
				local seenInDrum = {}
				
				-- Собирает все уникальные компоненты этого барабана
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

	-- Проверяет, сколько рецептов из кэша удовлетворяют собранному набору
	for _, recipe in pairs( self._state.recipeCache ) do
		if self:IsRecipeMatch( recipe, availableComponents, filledDrumsCount ) then
			potentialCount = potentialCount + 1
		end
	end

	-- Возвращает количество возможных рецептов и количество заполненных слотов
	return potentialCount, filledDrumsCount
end