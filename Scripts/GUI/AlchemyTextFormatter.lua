--------------------------------------------------------------------------------
-- GUI/AlchemyTextFormatter.lua
-- Форматировщик текста для вывода результатов алхимии.
-- Отвечает за подготовку, сортировку и форматирование списка найденных рецептов
-- перед их выводом в текстовый контейнер (ouText).
--------------------------------------------------------------------------------

Class( "AlchemyTextFormatter", {
	_classWidgetAlchemyV2 = nil,
	_template             = nil,
} )

--------------------------------------------------------------------------------
--- Инициализация форматировщика.
--- @param classWidgetAlchemyV2 table
--- @param templateService table
--------------------------------------------------------------------------------
function AlchemyTextFormatter:Init( classWidgetAlchemyV2, templateService )
	self._classWidgetAlchemyV2 = classWidgetAlchemyV2
	self._template             = templateService
end

--------------------------------------------------------------------------------
--- Отформатировать список найденных рецептов в массив объектов ValuedText.
--- Результаты сортируются по убыванию уровня умения (score), при равенстве: по имени.
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
    local currentRecipeName = self._classWidgetAlchemyV2:GetCurrentRecipeName()
	
	-- Локализованный шаблон строки рецепта "level:N |N |N |N |N - name"
    local recipeLineFormat = self._template:Get( "RECIPE_LINE" )
	
	-- Локализованный шаблон для значения с жёлтым цветом (<span color="0xFFFFFF00"><r name="val"/></span>)
	local colorYellowtextFormat = self._template:Get( "COLOR_YELLOW_TEXT" )
	
	
	local linesData = {}
	
	-- Создание строк для ТОП-N рецептов
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
        
        for drumIndex = 1, drumsCount do
			-- Форматирует сдвиг для отображения "% d"
            textValues[ "bulb" .. drumIndex ] = userMods.ToWString( string.format( "% d", -foundResult.shifts[ drumIndex ] ) )
        end
		
        table.insert( linesData, common.CreateValuedText( textValues ) )
    end

    return linesData
end

--------------------------------------------------------------------------------
--- Формат записи: score,shift1,shift2,shift3,shift4,shift5,name|score,shift1,...
--- EVENT_ALCHEMY_REACTION_FINISHED:123,1,-1,0,0,0,зелье|123,...
--- @param found table массив найденных результатов (recipe и shifts).
--- @param maxDisplay number максимальное количество строк для отображения (ТОП-N).
--- @param drumsCount number количество барабанов (для вывода сдвигов).
--- @return string
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