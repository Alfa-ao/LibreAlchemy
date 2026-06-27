-- UI/AlchemyWidgetManager.lua

Class( "AlchemyWidgetManager", {
    _mainForm = nil,
    _widgets = {},
} )

function AlchemyWidgetManager:Init( ... )
    self._mainForm = _G.mainForm
    self._widgets = {}
    
    local widgets = { ... }
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
    
    self:Hide()
end

-- Геттер для получения формы (чтобы виджеты не лазили в _mainForm напрямую)
function AlchemyWidgetManager:GetMainForm()
    return self._mainForm
end

-- Геттер конкретного виджета по имени
function AlchemyWidgetManager:GetWidget( widgetName )
    return self._widgets[widgetName]
end

function AlchemyWidgetManager:Show() self._mainForm:Show( true )  end
function AlchemyWidgetManager:Hide() self._mainForm:Show( false ) end