--------------------------------------------------------------------------------
-- HANDLERS
-- Вспомогательные функции для логики аддона.
--------------------------------------------------------------------------------

--- @function _G.LibreAlchemy.fn.InitLocale
--- @description Инициализирует локализацию (rus, eng etc.) текстовых данных.
_G.LibreAlchemy.fn.InitLocale = function()
    local group = common.GetAddonRelatedTextGroup( common.GetLocalization(), true ) or common.GetAddonRelatedTextGroup( "eng" )
    
    setmetatable( _G.LibreAlchemy.locales, 
    {
        __index = function( _, name )
            if group:HasText( name ) then
                return userMods.FromWString( group:GetText( name ) )
            end
        end
    } )
end

--- @function _G.LibreAlchemy.fn.wSetText
--- @description Вспомогательная функция для установки текста в виджет ouText.
--- @param tv string - Текстовая строка.
_G.LibreAlchemy.fn.wSetText = function( tv )
	if _G.LibreAlchemy.debug then
		common.LogInfo("", tv )
	end
	
	local vt = common.CreateValuedText()
	vt:SetFormat( userMods.ToWString( string.format( [[<html><log fontsize="20">%s</log></html>]], tv ) ) )
	_G.LibreAlchemy.widgets.ouText:SetValuedText( vt )
end

--- @function _G.LibreAlchemy.fn.MakeReciList
--- @description Формирует и кэширует список всех доступных рецептов алхимии для текущего персонажа.
_G.LibreAlchemy.fn.MakeReciList = function()
    -- Если список уже сформирован, повторно не создаем
    if _G.LibreAlchemy.lReci == nil then
        _G.LibreAlchemy.lReci = {}
        -- Получаем общую информацию об алхимии (включая список ID рецептов)
        local ainf = avatar.GetAlchemyInfo()
        for ir, vr in pairs( ainf.recipes ) do
            -- Получаем детальную информацию о каждом рецепте по его ID
            local gr = avatar.GetRecipeInfo( vr )
            -- Формируем структуру рецепта: cc - кол-во компонентов, wName - оригинальное имя, name - строковое имя, score - сложность/приоритет, cli - таблица компонентов {имя=кол-во}
            local lr = { cc = 0, wName = gr.name, name = userMods.FromWString( gr.name ), score = gr.score, cli = {} }
            for ic, vc in pairs( gr.components ) do
                -- Получаем информацию о каждом компоненте рецепта
                local co = avatar.GetComponentInfo( vc )
                local cn = userMods.FromWString( co.name )
                -- Считаем количество одинаковых компонентов в рецепте
                if lr.cli[cn] == nil then lr.cli[cn] = 1 else lr.cli[cn] = lr.cli[cn] + 1 end
                lr.cc = lr.cc + 1
            end
            _G.LibreAlchemy.lReci[ir] = lr
        end
    end
end

--------------------------------------------------------------------------------
-- ФУНКЦИИ ПОИСКА И АНАЛИЗА КОМБИНАЦИЙ СДВИГОВ
--------------------------------------------------------------------------------

--- @function _G.LibreAlchemy.fn.CopyTable
--- @description Создает поверхностную копию таблицы без мусора.
--- @param tbl table - Исходная таблица.
--- @return table|nil - Новая таблица с теми же ключами и значениями, или nil, если передан не table.
_G.LibreAlchemy.fn.CopyTable = function( tbl )
    if type( tbl ) ~= "table" then return nil end
    local copy = {}
    for k, v in pairs( tbl ) do
        copy[k] = v
    end
    return copy
end

--- @function _G.LibreAlchemy.fn.CountPotentialRecipes
--- @description Быстрая проверка: подсчитывает количество рецептов, которые теоретически могут быть созданы 
--- из компонентов, уже находящихся в барабанах (без учета сложных сдвигов, только наличие).
--- Используется в EVENT_ALCHEMY_ITEM_PLACED для раннего информирования игрока.
--- @return number potentialCount - Количество потенциально подходящих рецептов.
--- @return number filledDrumsCount - Количество барабанов, содержащих компоненты.
_G.LibreAlchemy.fn.CountPotentialRecipes = function()
    _G.LibreAlchemy.fn.MakeReciList()
    local potentialCount = 0
    local filledDrumsCount = 0
    local availableComponents = {}

    for drumIdx = 1, _G.LibreAlchemy.nDrums do
        local drumInfo = avatar.GetAlchemyDrumInfo( drumIdx - 1 )
        if drumInfo and drumInfo.itemId ~= nil then
            filledDrumsCount = filledDrumsCount + 1
            local drumUniqueComponents = {}

            if drumInfo.components then
                for _, compId in pairs( drumInfo.components ) do
                    local compInfo = avatar.GetComponentInfo( compId )
                    if compInfo then
                        local compName = userMods.FromWString( compInfo.name )
                        drumUniqueComponents[compName] = 1
                    end
                end
            end

            -- Агрегируем уникальные компоненты текущего барабана в общий счетчик
            for compName, _ in pairs( drumUniqueComponents ) do
                availableComponents[compName] = ( availableComponents[compName] or 0 ) + 1
            end
        end
    end

    -- Перебираем все известные рецепты и проверяем, хватает ли компонентов
    for _, recipe in pairs( _G.LibreAlchemy.lReci ) do
        if recipe.cc <= filledDrumsCount then
            local isPossible = true
            for reqCompName, reqCount in pairs( recipe.cli ) do
                -- Идиоматичная проверка: если компонента нет, (nil or 0) вернет 0
                if ( availableComponents[reqCompName] or 0 ) < reqCount then
                    isPossible = false
                    break
                end
            end
            if isPossible then
                potentialCount = potentialCount + 1
            end
        end
    end

    return potentialCount, filledDrumsCount
end

--- @function _G.LibreAlchemy.fn.RegisterBestMatchingRecipe
--- @description Проверяет, подходит ли какой-либо отфильтрованный рецепт под текущий набор компонентов (componentMap),
--- находит лучший по приоритету (score) и добавляет его в список найденных вариантов lFound, если его там еще нет.
--- @param componentMap table - Таблица компонентов {имя=кол-во} для проверки.
--- @param shiftMap table - Таблица сдвигов барабанов, при которых получился этот набор.
_G.LibreAlchemy.fn.RegisterBestMatchingRecipe = function( componentMap, shiftMap )
    if type( componentMap ) ~= "table" then return end

    local bestRecipe = nil

    -- Ищем рецепт с максимальным score, который можно собрать из компонентов componentMap
    for _, recipe in pairs( _G.LibreAlchemy.lFilt ) do
        local isMatch = true
        for reqCompName, reqCount in pairs( recipe.cli ) do
            if ( componentMap[reqCompName] or 0 ) < reqCount then
                isMatch = false
                break
            end
        end

        if isMatch then
            if bestRecipe == nil or recipe.score > bestRecipe.score then
                bestRecipe = recipe
            end
        end
    end

    if bestRecipe == nil then return end

    -- Проверяем, не добавлен ли уже этот рецепт в lFound (защита от дубликатов по имени)
    local alreadyFound = false
    for _, foundEntry in pairs( _G.LibreAlchemy.lFound ) do
        if foundEntry.rc.name == bestRecipe.name then
            alreadyFound = true
            break
        end
    end

    -- Если рецепт уникален для текущего набора сдвигов, добавляем его
    if not alreadyFound then
        table.insert( _G.LibreAlchemy.lFound, {
            rc = bestRecipe,
            sh = _G.LibreAlchemy.fn.CopyTable( shiftMap ),
            cmb = _G.LibreAlchemy.fn.CopyTable( componentMap )
        })
    end
end

--- @function _G.LibreAlchemy.fn.RecursiveShiftSearch
--- @description Рекурсивная функция (поиск с возвратом) для перебора всех возможных комбинаций сдвигов барабанов.
--- На каждом шаге формирует комбинации компонентов для разных линий результата и проверяет их.
--- @param drumIdx number - Индекс текущего обрабатываемого барабана (уменьшается при рекурсии, от nDrums до 1).
--- @param shiftsLeft number - Текущее общее количество доступных сдвигов (лимит коррекций).
--- @param currentShifts table - Таблица накопленных сдвигов для каждого барабана.
--- @param line0 table - Таблица компонентов для базовой линии результата (0).
--- @param lineMinus1 table|nil - Таблица компонентов для линии результата -1 (если доступна).
--- @param linePlus1 table|nil - Таблица компонентов для линии результата 1 (если доступна).
_G.LibreAlchemy.fn.RecursiveShiftSearch = function( drumIdx, shiftsLeft, currentShifts, line0, lineMinus1, linePlus1 )
    -- Если нашли все возможные отфильтрованные рецепты, прекращаем поиск
    if #_G.LibreAlchemy.lFilt > 0 and #_G.LibreAlchemy.lFound >= #_G.LibreAlchemy.lFilt then return end

    if drumIdx > 0 then
        -- Если в барабане нет компонентов, пропускаем его (сдвиг 0)
        if _G.LibreAlchemy.lCodr[drumIdx][0] == nil then
            if ( drumIdx > 1 ) or ( ( drumIdx == 1 ) and ( shiftsLeft == 0 ) ) then
                currentShifts[drumIdx] = 0
                _G.LibreAlchemy.fn.RecursiveShiftSearch( drumIdx - 1, shiftsLeft, currentShifts, line0, lineMinus1, linePlus1 )
            end
            return
        end

        local step = 1
        local maxShift = shiftsLeft

        -- Определяем шаг и лимит сдвигов для текущего барабана
        if drumIdx == 1 then
            if shiftsLeft > _G.LibreAlchemy.nSinshi then return end
            if shiftsLeft > 0 then step = 2 * shiftsLeft end
        else
            if shiftsLeft > _G.LibreAlchemy.nSinshi then maxShift = _G.LibreAlchemy.nSinshi end
        end

        -- Перебираем возможные сдвиги для текущего барабана
        for shift = -maxShift, maxShift, step do
            -- Копируем таблицы компонентов, чтобы не портить состояния из других веток рекурсии
            local nextLine0 = _G.LibreAlchemy.fn.CopyTable( line0 )
            local nextLineMinus1 = _G.LibreAlchemy.fn.CopyTable( lineMinus1 )
            local nextLinePlus1 = _G.LibreAlchemy.fn.CopyTable( linePlus1 )

            -- Вычисляем оставшиеся доступные сдвиги. 
            local nextShiftsLeft = shiftsLeft - math.abs( shift )
            local hasComponent = ( shift == 0 )
            local compName

            -- Линия 0 (базовая)
            if nextLine0 ~= nil then
                compName = _G.LibreAlchemy.lCodr[drumIdx][shift]
                if compName ~= nil then
                    nextLine0[compName] = ( nextLine0[compName] or 0 ) + 1
                    hasComponent = true
                end
            end

            -- Линия -1
            if nextLineMinus1 ~= nil then
                compName = _G.LibreAlchemy.lCodr[drumIdx][shift - 1]
                if compName ~= nil then
                    nextLineMinus1[compName] = ( nextLineMinus1[compName] or 0 ) + 1
                    hasComponent = true
                end
            end

            -- Линия +1
            if nextLinePlus1 ~= nil then
                compName = _G.LibreAlchemy.lCodr[drumIdx][shift + 1]
                if compName ~= nil then
                    nextLinePlus1[compName] = ( nextLinePlus1[compName] or 0 ) + 1
                    hasComponent = true
                end
            end

            -- Если хотя бы один компонент добавлен, идем глубже в рекурсию для следующего барабана
            if hasComponent then
                currentShifts[drumIdx] = shift
                _G.LibreAlchemy.fn.RecursiveShiftSearch( drumIdx - 1, nextShiftsLeft, currentShifts, nextLine0, nextLineMinus1, nextLinePlus1 )
            end
        end
    else
        -- Достигли конца рекурсии (drumIdx == 0), проверяем собранные комбинации компонентов
        _G.LibreAlchemy.fn.RegisterBestMatchingRecipe( line0, currentShifts )
        _G.LibreAlchemy.fn.RegisterBestMatchingRecipe( lineMinus1, currentShifts )
        _G.LibreAlchemy.fn.RegisterBestMatchingRecipe( linePlus1, currentShifts )
    end
end

--------------------------------------------------------------------------------
-- ФУНКЦИИ АНАЛИЗА БАРАБАНОВ И ФИЛЬТРАЦИИ РЕЦЕПТОВ
--------------------------------------------------------------------------------

--- @function _G.LibreAlchemy.fn.BuildDrumShiftMap
--- @description Считывает информацию о барабанах, строит карту сдвигов (lCodr) 
--- и агрегирует доступные уникальные компоненты в таблицу drc.
--- @return table drc - Таблица подсчета доступных компонентов {имя_компонента = количество}
--- @return number tdc - Количество барабанов, содержащих компоненты
_G.LibreAlchemy.fn.BuildDrumShiftMap = function()
    local drc = {}
    _G.LibreAlchemy.lCodr = {}
    local tdc = 0

    for dru = 1, _G.LibreAlchemy.nDrums do
        _G.LibreAlchemy.lCodr[dru] = {}
        local dri = avatar.GetAlchemyDrumInfo( dru - 1 )
        
        if dri.components ~= nil and type( dri.components ) == "table" then
            tdc = tdc + 1
            local d1c = {}
            
            -- Определяем длину таблицы компонентов.
            local compCount = #dri.components
            if compCount == 0 and dri.components[1] ~= nil then compCount = 1 end
            
            -- Перебираем возможные сдвиги компонентов в барабане
            for sh = -_G.LibreAlchemy.nSinshi, _G.LibreAlchemy.nSinshi do
                local cp = ( dri.position or 0 ) + sh
                
                -- Циклический сдвиг (wrap-around) для индексов.
                if cp < 0 then 
                    cp = cp + compCount 
                elseif cp >= compCount then 
                    cp = cp - compCount 
                end
                
                local targetIndex = cp
                if dri.components[targetIndex] == nil and dri.components[targetIndex + 1] ~= nil then
                    targetIndex = targetIndex + 1
                end

                if dri.components[targetIndex] ~= nil then
                    local gc = avatar.GetComponentInfo( dri.components[targetIndex] )
                    if gc ~= nil then
                        local compName = userMods.FromWString( gc.name )
                        -- Сохраняем имя компонента для данного барабана и сдвига
                        _G.LibreAlchemy.lCodr[dru][sh] = compName
                        d1c[compName] = 1
                    end
                end
            end
            
            -- Агрегируем уникальные компоненты текущего барабана в общий счетчик
            for compName, _ in pairs( d1c ) do
                drc[compName] = ( drc[compName] or 0 ) + 1
            end
        end
    end
    return drc, tdc
end

--- @function _G.LibreAlchemy.fn.FilterRecipes
--- @description Фильтрует список рецептов (lReci), оставляя только те, 
--- которые можно создать из компонентов, имеющихся в барабанах (drc).
--- @param drc table - Таблица доступных компонентов {имя_компонента = количество}
--- @param tdc number - Количество заполненных барабанов
--- @return number tc - Количество подходящих рецептов
_G.LibreAlchemy.fn.FilterRecipes = function( drc, tdc )
    -- Гарантируем наличие кэша рецептов перед фильтрацией
    _G.LibreAlchemy.fn.MakeReciList()
    
    _G.LibreAlchemy.lFilt = {}
    local tc = 0
    
    for _, vr in pairs( _G.LibreAlchemy.lReci ) do
        -- Если общее кол-во компонентов в рецепте больше, чем барабанов, пропускаем
        if vr.cc <= tdc then
            local isFit = true
            for reqCompName, reqCount in pairs( vr.cli ) do
                if ( drc[reqCompName] or 0 ) < reqCount then
                    isFit = false
                    break -- Нет смысла проверять дальше, рецепт не подходит
                end
            end
            
            if isFit then
                table.insert( _G.LibreAlchemy.lFilt, vr )
                tc = tc + 1
            end
        end
    end
    return tc
end

--- @function _G.LibreAlchemy.fn.BuildComponentMapAndFilter
--- @description Главная функция-оркестратор. Анализирует барабаны, строит карту сдвигов 
--- и фильтрует возможные рецепты.
--- @return number tc - Количество найденных подходящих рецептов
_G.LibreAlchemy.fn.BuildComponentMapAndFilter = function()
    -- Строим карту сдвигов и получаем агрегированные компоненты
    local drc, tdc = _G.LibreAlchemy.fn.BuildDrumShiftMap()
    
    -- Фильтруем рецепты на основе доступных компонентов
    local tc = _G.LibreAlchemy.fn.FilterRecipes( drc, tdc )
    
    return tc
end