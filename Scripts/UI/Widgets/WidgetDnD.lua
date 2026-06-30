-- UI/Widgets/WidgetDnD.lua

Class( "WidgetDnD", WidgetClassInterface() )

function WidgetDnD:Init( widgetManager ) --- void
    self._widgetManager = widgetManager
end

function WidgetDnD:InitDragAndDrop() --- boolean
    local ouTextWrapper = self._widgetManager:GetWidgetWrapper( "ouText" )
    
    if rawget( _G, "DnD" ) and ouTextWrapper then
        _G.DnD.Init( ouTextWrapper:GetNativeWidget(), nil, true )
        return true
    end
    return false
end

function WidgetDnD:GetWidgetName() --- string
    return "dnd"
end

function WidgetDnD:GetNativeWidget() --- ?Widget
    return rawget( _G, "DnD" ) and _G.DnD or nil
end