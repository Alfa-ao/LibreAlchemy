-- AlchemySearchService.lua
-- Сервис для построения карты сдвигов барабанов и рекурсивного поиска лучших комбинаций компонентов.

Class( "AlchemySearchService", {
    _state         = nil, -- Ссылка на глобальный объект состояния аддона (AlchemyState). Хранит drumsCount, maxCorrections, drumShiftMap, filteredRecipes, foundResults.
    _recipeService = nil, -- Ссылка на сервис рецептов (AlchemyRecipeService). Используется для получения имен компонентов и фильтрации рецептов.
    _foundSet      = nil, -- Хеш-таблица (Set) для отслеживания уже найденных рецептов. Ключ - имя рецепта (string), значение - true. Защищает от дубликатов.
} )

-- Инициализация сервиса
function AlchemySearchService:Init( state, recipeService )
    self._state         = state         -- Сохраняем ссылку на общее состояние
    self._recipeService = recipeService -- Сохраняем ссылку на сервис работы с рецептами
    self._foundSet      = {}            -- Инициализируем пустую таблицу для уникальных результатов
end

-- Локальная функция: безопасный математический модуль (остаток от деления).
-- В Lua оператор % для отрицательных чисел может возвращать отрицательный результат. 
-- Эта функция гарантирует, что результат всегда будет в диапазоне [0, b-1].
local function safeModulo( a, b )
    -- a: number (int) - делимое (например, basePos + shift)
    -- b: number (int) - делитель (например, количество компонентов в барабане)
    return ( ( a % b ) + b ) % b
end

-- Локальная функция: поверхностное (неглубокое) копирование таблицы.
-- Копирует только ключи и значения первого уровня. Вложенные таблицы копируются по ссылке.
local function shallowCopy( tbl )
    -- tbl: table - исходная таблица для копирования
    local copy = {} -- Новая таблица, в которую будут скопированы данные
    for k, v in pairs( tbl ) do 
        copy[ k ] = v 
    end
    return copy
end

-- Метод: Строит карту возможных сдвигов для каждого барабана.
-- Определяет, какие компоненты можно получить на каждом барабане при разных сдвигах.
function AlchemySearchService:BuildDrumShiftMap()
    local drumRequiredComponents = {} -- Таблица { [имя_компонента] = количество_барабанов }. 
                                      -- Считает, в скольких барабанах встречается каждый уникальный компонент.
    self._state.drumShiftMap = {}     -- Инициализируем карту сдвигов в состоянии. 
                                      -- Структура: { [индекс_барабана] = { [сдвиг] = "имя_компонента" } }
    local totalDrumsCount = 0         -- number (int). Счетчик барабанов, в которые реально положены предметы (itemId ~= nil).

    -- Проходим по всем доступным барабанам (от 1 до drumsCount)
    for drumIndex = 1, self._state.drumsCount do
        self._state.drumShiftMap[ drumIndex ] = {} -- Создаем пустую таблицу для сдвигов текущего барабана
        local drumInfo = avatar.GetAlchemyDrumInfo( drumIndex - 1 ) -- Получаем информацию о барабане из API игры
        
        -- Проверяем, что барабан существует и в него положен предмет
        if drumInfo and drumInfo.itemId ~= nil then
            totalDrumsCount = totalDrumsCount + 1 -- Увеличиваем счетчик заполненных барабанов
            local uniqueDrumComponents = {}       -- Таблица { [имя_компонента] = 1 }. Хранит уникальные компоненты ВНУТРИ одного барабана.
            local componentCount = GetTableSize( drumInfo.components ) -- number (int). Общее количество компонентов в предмете барабана.
            
            -- Защита от барабанов без компонентов (предмет есть, но компонентов нет)
            if componentCount > 0 then
                local basePos = drumInfo.position or 0 -- number (int). Текущая базовая позиция барабана (индекс компонента, который сейчас "в окне").
                
                -- Перебираем все возможные сдвиги от -maxCorrections до +maxCorrections
                for shift = -self._state.maxCorrections, self._state.maxCorrections do
                    -- Вычисляем целевой индекс компонента с учетом сдвига и зацикленности барабана
                    local targetIndex = safeModulo( basePos + shift, componentCount ) 
                    
                    local componentId = drumInfo.components[ targetIndex ] -- ID компонента (userdata/ResourceId)
                    if componentId then
                        -- Получаем человекочитаемое имя компонента через сервис рецептов
                        local componentName = self._recipeService:GetComponentName( componentId ) -- string или nil
                        if componentName then
                            -- Записываем в карту сдвигов: какой компонент получится при данном сдвиге
                            self._state.drumShiftMap[ drumIndex ][ shift ] = componentName
                            -- Отмечаем компонент как уникальный для этого барабана
                            uniqueDrumComponents[ componentName ] = 1
                        end
                    end
                end
            end
            
            -- Добавляем уникальные компоненты этого барабана в общий счетчик требуемых компонентов
            for componentName, _ in pairs( uniqueDrumComponents ) do
                drumRequiredComponents[ componentName ] = ( drumRequiredComponents[ componentName ] or 0 ) + 1
            end
        end
    end

    -- Возвращаем таблицу уникальных компонентов по барабанам и общее кол-во заполненных барабанов
    return drumRequiredComponents, totalDrumsCount
end

-- Метод: Главная точка входа для поиска. 
-- Последовательно вызывает построение карты, фильтрацию рецептов и рекурсивный перебор.
function AlchemySearchService:FindBestRecipes()
    local alchemyInfo = avatar.GetAlchemyInfo() -- Таблица с общей информацией об алхимии игрока (коррекции, слоты и т.д.)
    
    -- Пытаемся получить максимальное кол-во коррекций из первого барабана
    local firstDrumInfo = avatar.GetAlchemyDrumInfo( 0 ) -- Информация о нулевом (первом) барабане
    if firstDrumInfo and firstDrumInfo.maxCorrectionsPerColumn and firstDrumInfo.maxCorrectionsPerColumn > 0 then
        self._state.maxCorrections = firstDrumInfo.maxCorrectionsPerColumn -- number (int). Макс. сдвиг для одного барабана.
    end

    local totalCorrectionsAvailable = alchemyInfo.correctionCount or 0 -- number (int). Общее кол-во доступных очков коррекции у игрока.
    self._state.drumsCount = alchemyInfo.drumsCount or self._state.drumsCount -- number (int). Актуальное кол-во слотов (барабанов).

    -- Инициализируем таблицы для накопления компонентов по трем линиям результата (-1, 0, +1).
    -- Если линия недоступна, переменная будет nil, чтобы не тратить на неё ресурсы.
    local lineMinusOne = avatar.IsAlchemyLineAvailable( -1 ) and {} or nil -- Таблица { [имя] = кол-во } для линии -1
    local lineZero     = {}                                                -- Таблица { [имя] = кол-во } для линии 0 (всегда доступна)
    local linePlusOne  = avatar.IsAlchemyLineAvailable( 1 ) and {} or nil  -- Таблица { [имя] = кол-во } для линии +1

    -- Строим карту сдвигов и получаем компоненты, которые есть в барабанах
    local drumRequiredComponents, totalDrumsCount = self:BuildDrumShiftMap()
    
    -- Фильтруем глобальный кэш рецептов, оставляя только те, которые теоретически можно сварить из того, что лежит в барабанах
    self._recipeService:FilterByComponents( drumRequiredComponents, totalDrumsCount )

    -- Инициализируем таблицы для хранения итоговых результатов
    self._state.foundResults = {} -- Массив таблиц { recipe, shifts, components }
    self._foundSet = {}           -- Хеш-таблица для проверки на дубликаты

    -- Запускаем рекурсивный поиск, перебирая общее количество использованных очков коррекции (от 0 до максимума)
    for shiftsLeft = 0, totalCorrectionsAvailable do
        self:_RecursiveSearch(
            self._state.drumsCount, -- Начинаем перебор с последнего барабана
            shiftsLeft,             -- Максимум очков коррекции, которые мы можем "потратить" в этой ветке
            {},                     -- Пустая таблица для хранения выбранных сдвигов по барабанам
            lineZero,               -- Ссылки на накопители линий
            lineMinusOne, 
            linePlusOne
        )
    end

    return self._state.foundResults -- Возвращаем массив найденных лучших комбинаций
end

-- Метод: Рекурсивный поиск с откатом состояния (Backtracking).
-- Перебирает все возможные сдвиги для каждого барабана, накапливая компоненты в линиях.
function AlchemySearchService:_RecursiveSearch( drumIdx, shiftsLeft, currentShifts, lineZero, lineMinusOne, linePlusOne )
    local filteredRecipes = self._state.filteredRecipes -- Массив рецептов, прошедших начальную фильтрацию
    local foundResults = self._state.foundResults       -- Массив уже найденных итоговых результатов
    
    -- Если мы уже нашли все возможные отфильтрованные рецепты, дальше искать нет смысла
    if filteredRecipes and #filteredRecipes > 0 and #foundResults >= #filteredRecipes then 
        return 
    end

    -- Базовый случай рекурсии или переход к следующему барабану
    if drumIdx > 0 then
        -- Если для текущего барабана нет возможных сдвигов (он пустой или не инициализирован)
        if next( self._state.drumShiftMap[ drumIdx ] ) == nil then
            currentShifts[ drumIdx ] = 0 -- Фиксируем сдвиг 0
            -- Идем к следующему (предыдущему по индексу) барабану
            self:_RecursiveSearch( drumIdx - 1, shiftsLeft, currentShifts, lineZero, lineMinusOne, linePlusOne )
            currentShifts[ drumIdx ] = nil -- Откатываем состояние
            return
        end
        
        -- Вычисляем максимальный сдвиг для текущего барабана (ограничен оставшимися очками и глобальным лимитом)
        local maxShift = math.min( shiftsLeft, self._state.maxCorrections ) 
        
        -- Перебираем все возможные сдвиги для текущего барабана
        for shift = -maxShift, maxShift do 
            local nextLeft = shiftsLeft - math.abs( shift ) -- number (int). Очки коррекции, которые останутся для следующих барабанов.
            
            -- Переменные для отслеживания того, что мы добавили в линии (нужны для отката состояния)
            local addedZero, addedMinus, addedPlus = nil, nil, nil 
            
            -- Обработка линии 0 (текущая позиция)
            if lineZero then
                local comp = self._state.drumShiftMap[ drumIdx ][ shift ] -- Имя компонента при сдвиге `shift`
                if comp then
                    lineZero[ comp ] = ( lineZero[ comp ] or 0 ) + 1 -- Увеличиваем счетчик компонента в линии
                    addedZero = comp -- Запоминаем, что добавили
                end
            end
            
            -- Обработка линии -1 (сдвиг на 1 влево от текущего)
            if lineMinusOne then
                local comp = self._state.drumShiftMap[ drumIdx ][ shift - 1 ] -- Имя компонента при сдвиге `shift - 1`
                if comp then
                    lineMinusOne[ comp ] = ( lineMinusOne[ comp ] or 0 ) + 1
                    addedMinus = comp
                end
            end
            
            -- Обработка линии +1 (сдвиг на 1 вправо от текущего)
            if linePlusOne then
                local comp = self._state.drumShiftMap[ drumIdx ][ shift + 1 ] -- Имя компонента при сдвиге `shift + 1`
                if comp then
                    linePlusOne[ comp ] = ( linePlusOne[ comp ] or 0 ) + 1
                    addedPlus = comp
                end
            end
 
            -- Если хотя бы в одну линию что-то добавилось, имеет смысл идти глубже (рекурсия)
            if addedZero or addedMinus or addedPlus then
                currentShifts[ drumIdx ] = shift -- Фиксируем текущий сдвиг для этого барабана
                
                -- Рекурсивный вызов для следующего барабана
                self:_RecursiveSearch( drumIdx - 1, nextLeft, currentShifts, lineZero, lineMinusOne, linePlusOne )
                
                -- Backtracking
                currentShifts[ drumIdx ] = nil -- Убираем сдвиг
                
                -- Уменьшаем счетчики компонентов в линиях, которые мы увеличили перед рекурсией
                if addedZero then
                    lineZero[ addedZero ] = lineZero[ addedZero ] - 1
                    if lineZero[ addedZero ] == 0 then lineZero[ addedZero ] = nil end -- Чистим ключ, если счетчик обнулился
                end
                if addedMinus then
                    lineMinusOne[ addedMinus ] = lineMinusOne[ addedMinus ] - 1
                    if lineMinusOne[ addedMinus ] == 0 then lineMinusOne[ addedMinus ] = nil end
                end
                if addedPlus then
                    linePlusOne[ addedPlus ] = linePlusOne[ addedPlus ] - 1
                    if linePlusOne[ addedPlus ] == 0 then linePlusOne[ addedPlus ] = nil end
                end
            end
        end
    else
        -- Мы прошли все барабаны. Теперь регистрируем накопленные компоненты как потенциальные результаты для каждой линии.
        if lineZero then self:_RegisterBest( lineZero, currentShifts ) end
        if lineMinusOne then self:_RegisterBest( lineMinusOne, currentShifts ) end
        if linePlusOne then self:_RegisterBest( linePlusOne, currentShifts ) end
    end
end

-- Метод: Ищет лучший рецепт для накопленных компонентов и добавляет его в результаты.
function AlchemySearchService:_RegisterBest( componentMap, shiftMap )
    local filteredRecipes = self._state.filteredRecipes -- Берем отфильтрованные рецепты
    if not filteredRecipes then return end
    
    local bestRecipe = nil  -- Таблица лучшего найденного рецепта
    local bestScore = -1    -- number (int). Максимальный score (уровень) среди подходящих рецептов

    -- Ищем рецепт с максимальным score, который можно сварить из текущих компонентов
    for _, recipe in pairs( filteredRecipes ) do
        local isMatch = true -- Флаг: подходит ли рецепт под текущий набор компонентов
        
        -- Проверяем, хватает ли каждого компонента
        for componentName, requiredCount in pairs( recipe.requiredComponents ) do
            if ( componentMap[ componentName ] or 0 ) < requiredCount then
                isMatch = false -- Компонента не хватает, рецепт не подходит
                break
            end
        end
        
        -- Если рецепт подходит и его score выше текущего максимума
        if isMatch and recipe.score > bestScore then
            bestRecipe = recipe
            bestScore = recipe.score
        end
    end

    -- Если подходящий рецепт не найден, выходим
    if not bestRecipe then return end

    -- Проверяем, не добавляли ли мы уже этот рецепт (защита от дубликатов из-за разных линий или сдвигов)
    if self._foundSet[ bestRecipe.name ] then return end
    self._foundSet[ bestRecipe.name ] = true -- Помечаем рецепт как найденный

    -- Добавляем успешную комбинацию в итоговый массив результатов
    table.insert( self._state.foundResults, {
        recipe = bestRecipe,                      -- Таблица с данными рецепта (name, score, requiredComponents)
        shifts = shallowCopy( shiftMap ),         -- Копия таблицы сдвигов { [индекс_барабана] = сдвиг }
        components = shallowCopy( componentMap ), -- Копия таблицы накопленных компонентов { [имя] = кол-во }
    } )
end