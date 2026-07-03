--------------------------------------------------------------------------------
-- Scripts/Services/AlchemyTextContainerService.lua
-- Сервис для управления текстовым контейнером (TextContainer).
-- Предоставляет унифицированный интерфейс для очистки, добавления и вывода
-- текста в виджете-обертке (реализующем WidgetClassInterface).
--------------------------------------------------------------------------------

Class( "AlchemyTextContainerService", {
	_widgetWrapper = nil, -- Обертка над нативным текстовым виджетом (WidgetOuText).
} )

--------------------------------------------------------------------------------
-- Инициализация сервиса.
--------------------------------------------------------------------------------
function AlchemyTextContainerService:Init( widgetWrapper ) --- void
	self._widgetWrapper = widgetWrapper
end

--------------------------------------------------------------------------------
-- Установить набор строк в текстовый контейнер.
-- Полностью очищает контейнер перед добавлением новых строк.
--------------------------------------------------------------------------------
function AlchemyTextContainerService:SetLines( linesArray ) --- void
	-- linesArray: string | table - массив строк, объектов ValuedText/WString или одиночная строка.
	
	-- Если передана одиночная строка, оборачиваем её в таблицу
	if type( linesArray ) ~= "table" then
		linesArray = { linesArray }
	end
	
	-- Очистка всего, что было добавлено ранее
	self._widgetWrapper:RemoveItems()
	
	-- Последовательно добавляем (пушим) строки в контейнер
	for _, line in ipairs( linesArray ) do
        if type( line ) == "string" then
            line = userMods.ToWString( line )
        end
        
		self._widgetWrapper:PushBackText( line )
	end
	
	-- Принудительно вызываем репозицию для немедленного обновления размеров и layout
	self._widgetWrapper:ForceReposition()
end

--------------------------------------------------------------------------------
-- Установить одну строку в текстовый контейнер.
-- Является оберткой над SetLines для удобства работы с одиночными сообщениями.
--------------------------------------------------------------------------------
function AlchemyTextContainerService:SetSingleLine( text ) --- void
	-- text: string | WString | ValuedText - текст для отображения.
	self:SetLines( text )
end

--------------------------------------------------------------------------------
-- Полностью очистить текстовый контейнер от всех строк.
--------------------------------------------------------------------------------
function AlchemyTextContainerService:ClearAllLines() --- void
	self._widgetWrapper:RemoveItems()
	
	-- Принудительная репозиция после очистки для корректного схлопывания контейнера
	self._widgetWrapper:ForceReposition()
end