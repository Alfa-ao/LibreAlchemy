--------------------------------------------------------------------------------
-- Scripts/UI/AlchemyTextFormatter.lua
-- Форматировщик текста для вывода результатов алхимии.
-- Отвечает за подготовку, сортировку и форматирование списка найденных рецептов
-- перед их выводом в текстовый контейнер (ouText).
--------------------------------------------------------------------------------

Class( "AlchemyTextFormatter", {
	_config        = nil, -- ? не используем тут
	_services      = nil, -- Ссылка на контейнер сервисов (debug, locale, textContainer).
	_widgetManager = nil,
} )

--------------------------------------------------------------------------------
--- Инициализация форматировщика.
--- @param config table AlchemyConfig
--- @param widgetManager table AlchemyWidgetManager
--- @param services table Services
--------------------------------------------------------------------------------
function AlchemyTextFormatter:Init( config, widgetManager, services ) --- void
    self._config        = config
    self._services      = services
	self._widgetManager = widgetManager
    
    -- Передаем весь менеджер виджетов в сервис текстового контейнера
    self._services.textContainer:Init( widgetManager )
	-- Выводим в контейнер имя аддона как текст по умолчанию
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
--- @param nDrums number 2-5
--------------------------------------------------------------------------------
function AlchemyTextFormatter:DisplayResults( found, maxDisplay, nDrums ) --- void
	local linesData = self:FormatResults( found, maxDisplay, nDrums )
	self._services.textContainer:SetLines( table.unpack( linesData ) )
end

--------------------------------------------------------------------------------
--- Отформатировать список найденных рецептов в массив объектов ValuedText.
--- Результаты сортируются по убыванию уровня умения (score), при равенстве - по имени.
--- @param found table массив найденных результатов (см. AlchemySearchService:FindBestRecipes).
--- @param maxDisplay number максимальное количество строк для отображения (ТОП-N).
--- @param nDrums number количество барабанов (для вывода сдвигов).
--- @return table linesData { ValuedText, ... }
--------------------------------------------------------------------------------
function AlchemyTextFormatter:FormatResults( found, maxDisplay, nDrums )
	-- Сортировка: сначала по уровню (score) убывания, затем по имени (name) убывания
	table.sort( found, function( a, b )
		if a.recipe.score == b.recipe.score then
			return a.recipe.name > b.recipe.name
		end
		return a.recipe.score > b.recipe.score
	end )
	
	-- Получаем имя рецепта через обертку виджета AlchemyV2
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
		
		-- Красим только строку с нужным зельем.
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
--- Разультат варки со сдвигами барабанов в одну строку для лога.
--- Формат записи: score,shift1,shift2,shift3,shift4,shift5,name|score,shift1,...
--- @param found table массив найденных результатов (recipe и shifts).
--- @param maxDisplay number максимальное количество строк для отображения (ТОП-N).
--- @param nDrums number количество барабанов (для вывода сдвигов).
--- @return string -- EVENT_ALCHEMY_REACTION_FINISHED:123,1,-1,0,0,0,зелье|123,...
--------------------------------------------------------------------------------
function AlchemyTextFormatter:FormatResultsForLog( found, maxDisplay, nDrums )
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