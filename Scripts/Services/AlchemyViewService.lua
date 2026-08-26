--------------------------------------------------------------------------------
-- Services/AlchemyViewService.lua
-- Сервис для управления отображением UI (View слой).
-- Отвечает за форматирование и вывод сообщений в текстовый контейнер.
--------------------------------------------------------------------------------
Class( "AlchemyViewService" )

--------------------------------------------------------------------------------
--- Инициализация сервиса.
--- @param context table { textContainer, locale, formatter }
--------------------------------------------------------------------------------
function AlchemyViewService:Init( context )
    self._textContainer = context.textContainer
    self._locale        = context.locale
    self._formatter     = context.formatter
end

--------------------------------------------------------------------------------
--- Показывает GREETINGS / WELCOME_BACK сообщение.
--- @param messageType number CONFIG.MESSAGE_*
--------------------------------------------------------------------------------
function AlchemyViewService:ShowGreetings( messageType )
    if messageType == CONFIG.MESSAGE_WELCOME_BACK then
        self._textContainer:SetLines( self._locale:Get( "WELCOME_BACK" ) )
    elseif messageType == CONFIG.MESSAGE_GREETINGS then
        self._textContainer:SetLines( self._locale:Get( "GREETINGS" ) )
    end
end

--------------------------------------------------------------------------------
--- Показывает статус компонентов и количество возможных рецептов.
--- @param countRecipe number Количество найденных рецептов.
--- @param filledSlotsCount number Количество заполненных слотов.
--------------------------------------------------------------------------------
function AlchemyViewService:ShowPotentialRecipes( countRecipe, filledSlotsCount )
    if countRecipe > 0 then
        local vtCountRecipes = common.CreateValuedText {
            format = self._locale:Get( "COUNT_RECIPES" ),
            count  = countRecipe,
        }
        self._textContainer:SetLines( vtCountRecipes )
    elseif filledSlotsCount > 0 then
        self._textContainer:SetLines( self._locale:Get( "COMPONENTS_NOT_READY" ) )
    else
        self._textContainer:SetLines( self._locale:Get( "NOT_FOUND_RECIPES" ) )
    end
end

--------------------------------------------------------------------------------
--- Показывает результаты реакции (варки).
--- @param foundResults table Результаты поиска.
--- @param maxDisplay number Максимум строк для отображения.
--- @param drumsCount number Кол-во барабанов.
--------------------------------------------------------------------------------
function AlchemyViewService:ShowReactionResults( foundResults, maxDisplay, drumsCount )
    if #foundResults == 0 then
        self._textContainer:SetLines( self._locale:Get( "RESULT_GIBBERISH" ) )
    else
        local linesData = self._formatter:FormatResults( foundResults, maxDisplay, drumsCount )
        self._textContainer:SetLines( table.unpack( linesData ) )
    end
end

--------------------------------------------------------------------------------
--- Показывает поздравление с изменением списка рецептов.
--------------------------------------------------------------------------------
function AlchemyViewService:ShowCongratulation()
    self._textContainer:SetLines( self._locale:Get( "CONGRATULATION" ) )
end

--------------------------------------------------------------------------------
--- Показывает сообщение о получении предмета (для аватара).
--- @param potionName string Имя зелья.
--- @param count number Количество предметов.
--------------------------------------------------------------------------------
function AlchemyViewService:ShowItemTaken( potionName, count )
    local vtItem = common.CreateValuedText {
        format = self._locale:Get( "AVATAR_ITEM_TAKEN" ),
        name   = potionName,
        count  = count,
        class1 = "alchemy-yellow-text",
    }
    
    self._textContainer:SetLines( vtItem )
end

--------------------------------------------------------------------------------
--- Формат записи: score,shift1,shift2,shift3,shift4,shift5,name|score,shift1,...
--- EVENT_ALCHEMY_REACTION_FINISHED:123,1,-1,0,0,0,зелье|123,...
--- @param found table массив найденных результатов (recipe и shifts).
--- @param maxDisplay number максимальное количество строк для отображения (ТОП-N).
--- @param drumsCount number количество барабанов (для вывода сдвигов).
--- @return string
--------------------------------------------------------------------------------
function AlchemyViewService:ResultsForLog( found, maxDisplay, drumsCount )
	local parts = {}
	
	for i = 1, math.min( #found, maxDisplay ) do
		local foundResult = found[ i ]
		
		local logStr = string.format( "%d,%d", foundResult.recipe.score, -foundResult.shifts[ 1 ] )
		
		for drumIndex = 2, drumsCount do
			logStr = logStr .. string.format( ",%d", -foundResult.shifts[ drumIndex ] )
		end
		
		logStr = logStr .. "," .. userMods.FromWString( foundResult.recipe.name )
		table.insert( parts, logStr )
	end
	
	return "EVENT_ALCHEMY_REACTION_FINISHED:" .. table.concat( parts, "|" )
end

--------------------------------------------------------------------------------
--- Центрирует панель с подсказкой.
--------------------------------------------------------------------------------
function AlchemyViewService:UpdateCenterPanel()
    self._textContainer:UpdateCenterPanel()
end