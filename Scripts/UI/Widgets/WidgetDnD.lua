-- UI/Widgets/WidgetDnD.lua

Class( "WidgetDnD", WidgetClassInterface() )

function WidgetDnD:Init( widgetManager )
    self._widgetManager = widgetManager
end

function WidgetDnD:InitDragAndDrop()
    local ouText = self._widgetManager:GetWidget( "ouText" ):GetWidget()
    
    if rawget( _G, "DnD" ) then
        _G.DnD.Init( ouText, nil, true )
        return true
    end
    return false
end

function WidgetDnD:GetWidgetName()
    return "dnd"
end

function WidgetDnD:GetWidget()
    return rawget( _G, "DnD" ) and _G.DnD or nil
end