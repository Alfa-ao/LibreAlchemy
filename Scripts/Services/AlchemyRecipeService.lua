-- AlchemyRecipeService.lua
-- Сервис для работы с рецептами алхимии: кэширование, фильтрация и подсчет возможных рецептов.

Class( "AlchemyRecipeService", {
    _state = nil,               -- Ссылка на глобальный объект состояния аддона (AlchemyState). Хранит кэши рецептов и настройки.
	
    _componentNamesCache = {},  -- Хеш-таблица (кэш) для хранения имен компонентов. 
                                -- Структура: { [ComponentId (userdata)] = "ИмяКомпонента (string)" }. 
} )

-- Инициализация сервиса
function AlchemyRecipeService:Init( state )
    self._state = state
end

-- Вспомогательный метод: получение человекочитаемого имени компонента по его ID с использованием кэша.
function AlchemyRecipeService:GetComponentName( componentId )
    -- componentId: userdata (ComponentPropertyId/ResourceId).
    
    -- Если имя уже запрашивалось, возвращаем его сразу
    if self._componentNamesCache[componentId] then
        return self._componentNamesCache[componentId] -- string
    end
    
    -- componentInfo: table or nil. Содержит поля: id, name (WString), description (WString), image.
    local componentInfo = avatar.GetComponentInfo( componentId )
    
    if componentInfo then
        local name = userMods.FromWString( componentInfo.name ) -- string
        
        -- Сохраняем в кэш
        self._componentNamesCache[componentId] = name
        return name
    end
    
    return nil
end

-- Метод: Создает и кэширует полный список всех доступных игроку рецептов алхимии.
-- Вызывается один раз при открытии окна алхимии или при изменении списка рецептов.
function AlchemyRecipeService:CreateRecipeCache()
    -- Если кэш уже создан
    if self._state.recipeCache ~= nil then return end
    
    self._state.recipeCache = {} -- Массив для хранения рецептов
    
    -- Получаем базовую информацию об алхимии
    -- alchemyInfo: table. Содержит drumsCount, correctionCount, recipes (массив RecipeId) и т.д.
    local alchemyInfo = avatar.GetAlchemyInfo()
    
    -- Сохраняем актуальное количество слотов (барабанов) в состояние
    self._state.drumsCount = alchemyInfo.drumsCount -- number (int)

    -- Проходим по всем доступным игроку рецептам
    -- recipeId: userdata (RecipeId) - идентификатор ресурса рецепта
    for _, recipeId in pairs( alchemyInfo.recipes ) do
        -- Получаем детальную информацию о конкретном рецепте
        -- recipeInfo: table. Содержит name (WString), score (int), components (массив ComponentId) и т.д.
        local recipeInfo = avatar.GetRecipeInfo( recipeId )
        
        if recipeInfo then
            local recipe = {
                componentsCount = 0,                -- Общее количество компонентов, требуемых рецептом.
                name = userMods.FromWString( recipeInfo.name ), -- Локализованное имя зелья/рецепта.
                score = recipeInfo.score,           -- number (int). Необходимый уровень умения (score) для крафта.
                requiredComponents = {},            -- table. Хеш-таблица требуемых компонентов: { ["ИмяКомпонента"] = количество }.
            }

            -- Разбираем массив компонентов рецепта
            -- componentId: userdata (ComponentId) - ID компонента, входящего в рецепт
            for _, componentId in pairs( recipeInfo.components ) do
                local componentName = self:GetComponentName( componentId )
                
                if componentName then
                    -- Увеличиваем счетчик требуемого количества данного компонента
                    recipe.requiredComponents[componentName] = ( recipe.requiredComponents[componentName] or 0 ) + 1
                    -- Увеличиваем общий счетчик компонентов в рецепте
                    recipe.componentsCount = recipe.componentsCount + 1
                end
            end

            -- Добавляем готовую структуру рецепта в общий кэш
            table.insert( self._state.recipeCache, recipe )
        end
    end
end

-- Метод: Проверяет, соответствуют ли доступные компоненты требованиям конкретного рецепта.
function AlchemyRecipeService:IsRecipeMatch( recipe, availableComponents, filledSlotsCount )
    -- recipe: table - структура рецепта из кэша (содержит componentsCount, requiredComponents).
    -- availableComponents: table - хеш-таблица доступных компонентов { ["Имя"] = кол-во }.
    -- filledSlotsCount: number (int) - количество заполненных слотов (барабанов) в ступке.
    
    -- Количество заполненных слотов должно совпадать с требуемым кол-вом компонентов
    if recipe.componentsCount ~= filledSlotsCount then
        return false
    end
    
    -- Проверяем наличие каждого требуемого компонента
    for componentName, neededCount in pairs( recipe.requiredComponents ) do
        -- Если доступного компонента меньше, чем требуется
        if ( availableComponents[componentName] or 0 ) < neededCount then
            return false
        end
    end
    
    return true
end

-- Метод: Фильтрует глобальный кэш рецептов, оставляя только те, которым соответствуют
-- уникальные компоненты, лежащие в барабанах (без учета сдвигов/коррекций).
function AlchemyRecipeService:FilterByComponents( availableComponents, filledDrumsCount )
    -- availableComponents: table - { ["ИмяКомпонента"] = кол-во_слотов_с_этим_компонентом }.
    -- filledDrumsCount: number (int) - общее количество барабанов, в которые положены предметы.
    
    -- Проверяем чтобы кэш был
    self:CreateRecipeCache()
    
    self._state.filteredRecipes = {} -- Инициализируем массив для отфильтрованных рецептов
    local count = 0                  -- Счетчик подходящих рецептов.
    
    for _, recipe in pairs( self._state.recipeCache ) do
        if self:IsRecipeMatch( recipe, availableComponents, filledDrumsCount ) then
            table.insert( self._state.filteredRecipes, recipe )
            count = count + 1
        end
    end
    
    return count -- Возвращаем количество найденных подходящих рецептов
end

-- Метод: Подсчитывает количество потенциально возможных рецептов на основе того, какие предметы физически положены в слоты.
function AlchemyRecipeService:CountPotential()
    -- Проверяем чтобы кэш был
    self:CreateRecipeCache()
    
    local potentialCount = 0       -- Итоговое количество рецептов.
    local filledDrumsCount = 0     -- Счетчик слотов, в которые положены предметы (itemId ~= nil).
    local availableComponents = {} -- table. Хеш-таблица: { ["ИмяКомпонента"] = кол-во_слотов_с_этим_компонентом }.

    -- Проходим по всем слотам (барабанам)
    for drumIdx = 1, self._state.drumsCount do
        -- Получаем информацию о барабане (нумерация с 0)
        -- drumInfo: table or nil. Содержит itemId, components (массив ComponentId), position и др.
        local drumInfo = avatar.GetAlchemyDrumInfo( drumIdx - 1 )
        
        -- Проверяем, что барабан существует и в него положен предмет
        if drumInfo and drumInfo.itemId ~= nil then
            filledDrumsCount = filledDrumsCount + 1 -- Считаем заполненный слот

            -- Если в барабане есть компоненты (предмет не пустой)
            if drumInfo.components then
                local seenInDrum = {} -- table (Set). Хеш-таблица для учета УНИКАЛЬНЫХ компонентов внутри ОДНОГО барабана.
                                      -- Структура: { ["ИмяКомпонента"] = true }.
                
                -- Собираем все уникальные компоненты этого барабана
                for _, componentId in pairs( drumInfo.components ) do
                    local componentName = self:GetComponentName( componentId )
                    if componentName then
                        seenInDrum[componentName] = true
                    end
                end
                
                -- Каждый уникальный компонент в барабане добавляет +1 к счетчику доступных компонентов
                for componentName, _ in pairs( seenInDrum ) do
                    availableComponents[componentName] = ( availableComponents[componentName] or 0 ) + 1
                end
            end
        end
    end

    -- Теперь проверяем, сколько рецептов из кэша удовлетворяют собранному набору
    for _, recipe in pairs( self._state.recipeCache ) do
        if self:IsRecipeMatch( recipe, availableComponents, filledDrumsCount ) then
            potentialCount = potentialCount + 1
        end
    end

    -- Возвращаем количество возможных рецептов и количество заполненных слотов
    return potentialCount, filledDrumsCount
end