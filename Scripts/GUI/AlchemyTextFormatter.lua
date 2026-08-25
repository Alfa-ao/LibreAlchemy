--------------------------------------------------------------------------------
-- GUI/AlchemyTextFormatter.lua
-- Форматировщик текста для вывода результатов алхимии.
-- Подготавливает, сортирует и форматирует список найденных рецептов
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
	
	-- Имя рецепта из AlchemyV2
    local currentRecipeName = self._classWidgetAlchemyV2:GetCurrentRecipeName()
	
	-- Шаблон строки рецепта "level:N |N |N |N |N - name"
    local recipeLineFormat = self._template:Get( "RECIPE_LINE" )
	
	-- Шаблон для значения с жёлтым цветом (<span color="0xFFFFFF00"><r name="val"/></span>)
	--local colorYellowtextFormat = self._template:Get( "COLOR_YELLOW_TEXT" )
	
	local linesData = {}
	
	-- Создание строк для ТОП-N рецептов
    for i = 1, math.min( #found, maxDisplay ) do
        local foundResult = found[ i ]
        
        -- Таблица значений для подстановки в основной шаблон
        local textValues = {
            format = recipeLineFormat,
            level  = foundResult.recipe.score,
            name   = foundResult.recipe.name,
            class1 = currentRecipeName == foundResult.recipe.name and "alchemy-yellow-text" or nil
        }
        
        for drumIndex = 1, drumsCount do
			-- Форматирует сдвиг для отображения "% d"
            textValues[ "bulb" .. drumIndex ] = userMods.ToWString( string.format( "% d", -foundResult.shifts[ drumIndex ] ) )
        end
		
        table.insert( linesData, common.CreateValuedText( textValues ) )
    end

    return linesData
end