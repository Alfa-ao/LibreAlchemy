--------------------------------------------------------------------------------
-- UI/Widgets/WidgetOuText.lua
-- Обертка над нативным текстовым контейнером (ouText).
--------------------------------------------------------------------------------

Class( "WidgetOuText", WidgetClassInterface() )

--------------------------------------------------------------------------------
--- Инициализация виджета.
--- @param widgetManager table - экземпляр класса AlchemyWidgetManager
--------------------------------------------------------------------------------
function WidgetOuText:Init( widgetManager ) --- void
    self._widgetManager = widgetManager
    
    -- ouText является дочерним элементом Panel
    local panel = widgetManager:GetMainForm():GetChildChecked( "Panel" )
    self._widget = panel:GetChildChecked( "ouText" )
end

--------------------------------------------------------------------------------
-- Реализация методов интерфейса WidgetClassInterface.
--------------------------------------------------------------------------------
--- @return number
function WidgetOuText:GetPriorityClass() 
    return 10 
end

--- @return userdata | table | nil
function WidgetOuText:GetNativeWidget()
    return self._widget 
end

--- @return string
function WidgetOuText:GetWidgetName()
    return "ouText" 
end

--------------------------------------------------------------------------------
-- Методы-обертки для работы с содержимым текстового контейнера.
--------------------------------------------------------------------------------
--- @param text WString | ValuedText
function WidgetOuText:PushBackText( text ) --- void
    self._widget:PushBackText( text )
end

--- @param pos number
function WidgetOuText:RemoveAt( pos ) --- void
    self._widget:RemoveAt( pos )
end

function WidgetOuText:RemoveItems() --- void
    self._widget:RemoveItems()
end

function WidgetOuText:ForceReposition() --- void
    self._widget:ForceReposition()
end

--------------------------------------------------------------------------------
--- Возвращает точную пиксельную высоту текущего текстового контента.
--- Использует внутренний __Content.
--- @return number
--------------------------------------------------------------------------------
function WidgetOuText:GetExactTextHeight()
    self:ForceReposition()
    
    local content = self._widget:GetChildChecked( "__Content", true )
    local contentPlc = content:GetPlacementPlain()
    return contentPlc.posY + contentPlc.sizeY
end