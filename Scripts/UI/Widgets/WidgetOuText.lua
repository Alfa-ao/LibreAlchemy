--------------------------------------------------------------------------------
-- UI/Widgets/WidgetOuText.lua
-- Обертка над нативным текстовым контейнером (ouText).
--------------------------------------------------------------------------------

Class( "WidgetOuText", WidgetClassInterface() )

--------------------------------------------------------------------------------
-- Инициализация виджета.
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
function WidgetOuText:GetPriorityClass() --- int 
    return 10 
end

function WidgetOuText:GetNativeWidget() --- ?Widget 
    return self._widget 
end

function WidgetOuText:GetWidgetName() --- string 
    return "ouText" 
end

--------------------------------------------------------------------------------
-- Методы-обертки для работы с содержимым текстового контейнера.
--------------------------------------------------------------------------------
function WidgetOuText:PushBackText( text ) --- void
    self._widget:PushBackText( text )
end

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
-- Возвращает точную пиксельную высоту текущего текстового контента.
-- Использует внутренний __Content.
--------------------------------------------------------------------------------
function WidgetOuText:GetExactTextHeight() --- number
    self:ForceReposition()
    
    local content = self._widget:GetChildChecked( "__Content", true )
    local contentPlc = content:GetPlacementPlain()
    return contentPlc.posY + contentPlc.sizeY
end