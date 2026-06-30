-- UI/AlchemyWidgetManager.lua

Class( "AlchemyWidgetManager", {
    _mainForm = nil,
    _widgets = {},
} )

function AlchemyWidgetManager:Init( ... ) --- void
    self._mainForm = _G.mainForm
    self._widgets = {}
    
    local widgets = { ... }
    
    table.sort( widgets, function( widgetA, widgetB )
		return widgetA:GetPriorityClass() > widgetB:GetPriorityClass()
	end )
    
    for _, widget in ipairs( widgets ) do
        if widget and InstanceOf( widget, _G.WidgetClassInterface ) then
            local widgetName = widget:GetWidgetName()
            self._widgets[widgetName] = widget
            
            -- Вызываем внутренний Init виджета, передавая ему ссылку на менеджер
            if widget.Init then
                widget:Init( self )
            end
        else
            local objectClass = GetParentClass( widget )
            local className = GetClassName( objectClass )
            
            error( string.format( 
                "Unsupported class '%s' does not have an interface 'WidgetClassInterface'", 
                className 
            ) )
        end
    end
end

-- Геттер для получения формы (чтобы виджеты не лазили в _mainForm напрямую)
function AlchemyWidgetManager:GetMainForm() --- Widget
    return self._mainForm
end

-- Геттер конкретного виджета по имени (Выводит контроллер/класс/обвертку над нативным)
function AlchemyWidgetManager:GetWidgetWrapper( widgetName ) --- ?WidgetClassInterface
    return self._widgets[widgetName] or nil
end

function AlchemyWidgetManager:Show() self._mainForm:Show( true )  end
function AlchemyWidgetManager:Hide() self._mainForm:Show( false ) end