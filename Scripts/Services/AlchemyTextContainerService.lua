--------------------------------------------------------------------------------
-- Scripts/Services/AlchemyTextContainerService.lua
-- Сервис для управления текстовым контейнером (TextContainer).
-- Предоставляет унифицированный интерфейс для очистки, добавления и вывода
-- текста в виджете-обертке (реализующем WidgetClassInterface).
--------------------------------------------------------------------------------

Class( "AlchemyTextContainerService", {
	_widgetManager = nil,
} )

--------------------------------------------------------------------------------
--- Инициализация сервиса.
--- @param widgetManager table - экземпляр класса AlchemyWidgetManager
--------------------------------------------------------------------------------
function AlchemyTextContainerService:Init( widgetManager ) --- void
	self._widgetManager = widgetManager
end

--------------------------------------------------------------------------------
--- Установить набор строк в текстовый контейнер.
--- Полностью очищает контейнер перед добавлением новых строк.
--- @param linesArray string | WString | table - ( массив строк, объектов ValuedText/WString ) или одиночная строка.
--------------------------------------------------------------------------------
function AlchemyTextContainerService:SetLines( linesArray ) --- void
	-- Если передана одиночная строка, оборачиваем её в таблицу
	if type( linesArray ) ~= "table" then
		linesArray = { linesArray }
	end
	
	local ouTextWrapper = self._widgetManager:GetWidgetWrapper( "ouText" )
    local panelWrapper = self._widgetManager:GetWidgetWrapper( "panel" )

    -- Очистка всего, что было добавлено ранее
    ouTextWrapper:RemoveItems()
	
	-- Последовательно добавляем (пушим) строки в контейнер
	for _, line in ipairs( linesArray ) do
        if type( line ) == "string" then
            line = userMods.ToWString( line )
        end
        
		ouTextWrapper:PushBackText( line )
	end
	
	-- Узнаем точную высоту текста и заставляем Panel подстроиться
    local exactHeight = ouTextWrapper:GetExactTextHeight()
    panelWrapper:UpdateSize( exactHeight )
end

--------------------------------------------------------------------------------
--- Установить одну строку в текстовый контейнер.
--- Является оберткой над SetLines для удобства работы с одиночными сообщениями.
--- @param text string | WString | ValuedText - текст для отображения.
--------------------------------------------------------------------------------
function AlchemyTextContainerService:SetSingleLine( text ) --- void
	self:SetLines( text )
end

--------------------------------------------------------------------------------
--- Полностью очистить текстовый контейнер от всех строк.
--------------------------------------------------------------------------------
function AlchemyTextContainerService:ClearAllLines() --- void
    local ouTextWrapper = self._widgetManager:GetWidgetWrapper( "ouText" )
    local panelWrapper = self._widgetManager:GetWidgetWrapper( "panel" )

    ouTextWrapper:RemoveItems()
    ouTextWrapper:ForceReposition()
    
    -- При очистке высота текста равна 0
    panelWrapper:UpdateSize( 0 )
end