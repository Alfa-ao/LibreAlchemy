--------------------------------------------------------------------------------
-- UI/AlchemyTextFormatter.lua
-- Форматировщик текста для вывода результатов алхимии.
-- Отвечает за подготовку, сортировку и форматирование списка найденных рецептов
-- перед их выводом в текстовый контейнер (ouText).
--------------------------------------------------------------------------------

Class( "AlchemyTextFormatter" )

--------------------------------------------------------------------------------
--- Инициализация форматировщика.
--- @param context table AlchemyContext
--------------------------------------------------------------------------------
function AlchemyTextFormatter:Init( context ) --- void
	self._widgetManager = context:GetWidgetManager() -- AlchemyWidgetManager
    self._services      = context:GetServices()      -- Cервисы
    
    -- Передаем весь менеджер виджетов в сервис текстового контейнера
    self._services.textContainer:Init( self._widgetManager )
	-- Вывод в контейнер имя аддона как текст по умолчанию
	self._services.textContainer:SetSingleLine( common.GetAddonName() )
end

--------------------------------------------------------------------------------
--- Установить текст в контейнер.
--- @param ... string | WString | ValuedText
--------------------------------------------------------------------------------
function AlchemyTextFormatter:SetText( ... ) --- void
	----------------------------------------
	self._services.debug:LogGeneral( ... )
	----------------------------------------
	
	self._services.textContainer:SetLines( ... )
end

--------------------------------------------------------------------------------
--- Отобразить список найденных рецептов в текстовом контейнере.
--- Выполняет форматирование и передает готовые ValuedText в сервис контейнера.
--- @param found table см. AlchemySearchService:FindBestRecipes
--- @param maxDisplay number MAX_DISPLAY_RESULTS
--- @param drumsCount number 2-5
--------------------------------------------------------------------------------
function AlchemyTextFormatter:DisplayResults( found, maxDisplay, drumsCount ) --- void
	local linesData = self:FormatResults( found, maxDisplay, drumsCount )
	self._services.textContainer:SetLines( table.unpack( linesData ) )
end

--------------------------------------------------------------------------------
--- Отформатировать список найденных рецептов в массив объектов ValuedText.
--- Результаты сортируются по убыванию уровня умения (score), при равенстве - по имени.
--- @param found table массив найденных результатов (см. AlchemySearchService:FindBestRecipes).
--- @param maxDisplay number максимальное количество строк для отображения (ТОП-N).
--- @param drumsCount number количество барабанов (для вывода сдвигов).
--- @return table linesData { ValuedText, ... }
--------------------------------------------------------------------------------
function AlchemyTextFormatter:FormatResults( found, maxDisplay, drumsCount )
	-- Сортировка: сначала по уровню (score) убывания, затем по имени (name) убывания
	table.sort( found, function( a, b )
		if a.recipe.score == b.recipe.score then
			return a.recipe.name > b.recipe.name
		end
		return a.recipe.score > b.recipe.score
	end )
	
	-- Имя рецепта через обертку виджета AlchemyV2
    local currentRecipeName = self._widgetManager:
		GetWidgetWrapper( "AlchemyV2" ):
		GetCurrentRecipeName()
	
	local linesData = {}
	
	-- Локализованный шаблон строки рецепта "level:N |N |N |N |N - name"
    local recipeLineFormat = self._services.template:Get( "RECIPE_LINE" )
	
	-- Локализованный шаблон для значения с жёлтым цветом (<span color="0xFFFFFF00"><r name="val"/></span>)
	local colorYellowtextFormat = self._services.template:Get( "COLOR_YELLOW_TEXT" )
	
	-- Создание строк для ТОП-N рецептов (ограничено maxDisplay)
    for i = 1, math.min( #found, maxDisplay ) do
        local foundResult = found[ i ]
        
        -- Стандартные значения
        local levelValue = foundResult.recipe.score
        local nameValue  = userMods.ToWString( foundResult.recipe.name )
		
		-- Красим только строку с конкретным зельем.
        -- Если строка подходит под условие, оборачиваем значения в ValuedText с желтым цветом
        if currentRecipeName == nameValue then
			-- Уровень зелья
            levelValue = common.CreateValuedText( {
                format = colorYellowtextFormat,
                val    = levelValue
            } )
            
			-- Название зелья
            nameValue = common.CreateValuedText( {
                format = colorYellowtextFormat,
                val    = nameValue
            } )
        end

        -- Таблица значений для подстановки в основной шаблон
        local textValues = {
            format = recipeLineFormat,
            level  = levelValue, -- число, либо цветной ValuedText
            name   = nameValue,  -- WString, либо цветной ValuedText
        }
        
        -- Заполняет параметры сдвигов для каждого барабана (bulb1, bulb2, ...)
        for drumIndex = 1, drumsCount do
			-- Форматирует сдвиг для отображения "% d"
            textValues[ "bulb" .. drumIndex ] = userMods.ToWString( string.format( "% d", -foundResult.shifts[ drumIndex ] ) )
        end
		
        table.insert( linesData, common.CreateValuedText( textValues ) )
    end

    return linesData
end

--------------------------------------------------------------------------------
--- Разультат варки со сдвигами барабанов в одну строку для лога.
--- Формат записи: score,shift1,shift2,shift3,shift4,shift5,name|score,shift1,...
--- @param found table массив найденных результатов (recipe и shifts).
--- @param maxDisplay number максимальное количество строк для отображения (ТОП-N).
--- @param drumsCount number количество барабанов (для вывода сдвигов).
--- @return string -- EVENT_ALCHEMY_REACTION_FINISHED:123,1,-1,0,0,0,зелье|123,...
--------------------------------------------------------------------------------
function AlchemyTextFormatter:FormatResultsForLog( found, maxDisplay, drumsCount )
	local parts = {}
	
	for i = 1, math.min( #found, maxDisplay ) do
		local foundResult = found[ i ]
		
		-- Начало формирования строки с уровня и первого сдвига
		local logStr = string.format( "%d,%d", foundResult.recipe.score, -foundResult.shifts[ 1 ] )
		
		-- Добавление остальных сдвигов через запятую
		for drumIndex = 2, drumsCount do
			logStr = logStr .. string.format( ",%d", -foundResult.shifts[ drumIndex ] )
		end
		
		-- Добавляет имя рецепта в конец строки
		logStr = logStr .. "," .. foundResult.recipe.name
		table.insert( parts, logStr )
	end
	
	return "EVENT_ALCHEMY_REACTION_FINISHED:" .. table.concat( parts, "|" )
end