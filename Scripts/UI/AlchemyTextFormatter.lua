--------------------------------------------------------------------------------
-- Scripts/UI/AlchemyTextFormatter.lua
-- Форматировщик текста для вывода результатов алхимии.
-- Отвечает за подготовку, сортировку и форматирование списка найденных рецептов
-- перед их выводом в текстовый контейнер (ouText) и в лог.
--------------------------------------------------------------------------------

Class( "AlchemyTextFormatter", {
	_config        = nil, -- Ссылка на конфигурацию аддона (AlchemyConfig).
	_services      = nil, -- Ссылка на контейнер сервисов (debug, locale, textContainer).
	_widgetManager = nil, -- Ссылка на менеджер виджетов (AlchemyWidgetManager).
} )

--------------------------------------------------------------------------------
-- Инициализация форматировщика.
--------------------------------------------------------------------------------
function AlchemyTextFormatter:Init( config, widgetManager, services ) --- void
    self._config        = config
    self._services      = services
	self._widgetManager = widgetManager
    
    -- Передаем весь менеджер виджетов в сервис текстового контейнера
    self._services.textContainer:Init( widgetManager )
	-- Выводим имя аддона как текст по умолчанию
	self._services.textContainer:SetSingleLine( common.GetAddonName() )
end

--------------------------------------------------------------------------------
-- Установить произвольный текст в контейнер и продублировать его в общий лог.
--------------------------------------------------------------------------------
function AlchemyTextFormatter:SetText( text ) --- void
	self._services.debug:LogGeneral( text )
	self._services.textContainer:SetLines( text )
end

--------------------------------------------------------------------------------
-- Отобразить список найденных рецептов в текстовом контейнере.
-- Выполняет форматирование и передает готовые ValuedText в сервис контейнера.
--------------------------------------------------------------------------------
function AlchemyTextFormatter:DisplayResults( found, maxDisplay, nDrums ) --- void
	local linesData = self:FormatResults( found, maxDisplay, nDrums )
	self._services.textContainer:SetLines( linesData )
end

--------------------------------------------------------------------------------
-- Отформатировать список найденных рецептов в массив объектов ValuedText.
-- Результаты сортируются по убыванию уровня умения (score), при равенстве - по имени.
--------------------------------------------------------------------------------
function AlchemyTextFormatter:FormatResults( found, maxDisplay, nDrums ) --- table
	-- found: table - массив найденных результатов (содержит recipe и shifts).
	-- maxDisplay: number (int) - максимальное количество строк для отображения (ТОП-N).
	-- nDrums: number (int) - количество барабанов (для вывода сдвигов).
	
	-- Сортировка: сначала по уровню (score) убывания, затем по имени (name) убывания
	table.sort( found, function( a, b )
		if a.recipe.score == b.recipe.score then
			return a.recipe.name > b.recipe.name
		end
		return a.recipe.score > b.recipe.score
	end )
	
	-- Получаем имя текущего рецепта через обертку виджета AlchemyV2
    local currentRecipeName = self._widgetManager:
		GetWidgetWrapper( "AlchemyV2" ):
		GetCurrentRecipeName()
	
	local linesData = {}
	
	-- Получаем локализованный шаблон строки рецепта "level:N |N |N |N |N - name"
    local recipeLineFormat = self._services.locale:Get( "RECIPE_LINE" )
	
	-- Формируем строки для ТОП-N рецептов (ограничено maxDisplay)
    for i = 1, math.min( #found, maxDisplay ) do
        local foundResult = found[ i ]
        
        -- Стандартные значения
        local levelValue = foundResult.recipe.score
        local nameValue  = userMods.ToWString( foundResult.recipe.name )
		
		-- Красим только строку с соответсвующим зельем.
        -- Если строка подходит под условие, оборачиваем значения в ValuedText с желтым цветом
        if currentRecipeName == foundResult.recipe.name then
			-- Уровень зелья
            levelValue = common.CreateValuedText({
                format = '<html><span color="0xFFFFFF00"><r name="val"/></span></html>',
                val    = levelValue
            })
            
			-- Название зелья
            nameValue = common.CreateValuedText({
                format = '<html><span color="0xFFFFFF00"><r name="val"/></span></html>',
                val    = nameValue
            })
        end

        -- Таблица значений для подстановки в основной шаблон
        local textValues = {
            format = recipeLineFormat,
            level  = levelValue, -- число, либо цветной ValuedText
            name   = nameValue,  -- WString, либо цветной ValuedText
        }
        
        -- Заполняем параметры сдвигов для каждого барабана (bulb1, bulb2, ...)
        for drumIndex = 1, nDrums do
			-- Инвертируем сдвиг для отображения и форматируем с ведущим пробелом/знаком
            textValues[ "bulb" .. drumIndex ] = userMods.ToWString( string.format( "% d", -foundResult.shifts[ drumIndex ] ) )
        end

        -- Создаем готовый ValuedText и добавляем в массив строк
        table.insert( linesData, common.CreateValuedText( textValues ) )
    end

    return linesData
end

--------------------------------------------------------------------------------
-- Разультат варки со сдвигами барабанов в одну строку для лога.
-- Формат записи: score,shift1,shift2,shift3,shift4,shift5,name|score,shift1,...
--------------------------------------------------------------------------------
function AlchemyTextFormatter:FormatResultsForLog( found, maxDisplay, nDrums ) --- string
	local parts = {}
	
	for i = 1, math.min( #found, maxDisplay ) do
		local foundResult = found[ i ]
		
		-- Начинаем формирование строки с уровня и первого сдвига
		local logStr = string.format( "%d,%d", foundResult.recipe.score, -foundResult.shifts[ 1 ] )
		
		-- Добавляем остальные сдвиги через запятую
		for drumIndex = 2, nDrums do
			logStr = logStr .. string.format( ",%d", -foundResult.shifts[ drumIndex ] )
		end
		
		-- Добавляем имя рецепта в конец строки
		logStr = logStr .. "," .. foundResult.recipe.name
		table.insert( parts, logStr )
	end
	
	return "EVENT_ALCHEMY_REACTION_FINISHED:" .. table.concat( parts, "|" )
end