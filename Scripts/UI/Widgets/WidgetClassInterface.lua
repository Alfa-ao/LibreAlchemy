-- UI/Widgets/WidgetClassInterface.lua

Class( "WidgetClassInterface", {
    _widgetManager = nil,
} )

function WidgetClassInterface:GetWidget()
    error( "WidgetClassInterface:GetWidget must be implemented by subclass" )
end

function WidgetClassInterface:GetWidgetName()
    error( "WidgetClassInterface:GetWidgetName must be implemented by subclass" )
end