-- UI/Widgets/WidgetClassInterface.lua

Class( "WidgetClassInterface", {
    _widgetManager = nil,
} )

-- Прямой геттер нативного виджета (если нужен для специфичных операций)
function WidgetClassInterface:GetNativeWidget() --- ?Widget
    error( "WidgetClassInterface:GetNativeWidget must be implemented by subclass" )
end

function WidgetClassInterface:GetWidgetName() --- string
    error( "WidgetClassInterface:GetWidgetName must be implemented by subclass" )
end

-- Стандартный приоритет инициализации. 
-- Чем больше число, тем раньше виджет будет инициализирован менеджером.
function WidgetClassInterface:GetPriorityClass() --- int
	return 0
end