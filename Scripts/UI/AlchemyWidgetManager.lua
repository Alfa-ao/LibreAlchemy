--------------------------------------------------------------------------------
-- Scripts/UI/AlchemyWidgetManager.lua
-- Менеджер виджетов аддона (AlchemyWidgetManager).
--------------------------------------------------------------------------------

Class( "AlchemyWidgetManager", {
	_mainForm = nil,  -- Ссылка на главную форму аддона (mainForm).
	_widgets  = nil,  -- Хеш-таблица зарегистрированных виджетов-оберток { ["widgetName"] = WidgetClassInterface }.
	_context  = nil,  -- AlchemyContext
} )

--------------------------------------------------------------------------------
--- Инициализация менеджера.
--- @param widgets table WidgetClassInterface
--- @param context table AlchemyContext
--------------------------------------------------------------------------------
function AlchemyWidgetManager:Init( widgets, context ) --- void
	self._mainForm = _G.mainForm
	self._widgets = {}
	self._context = context
	
	-- Сортировка виджетов по убыванию приоритета (чем больше число, тем раньше инициализируется)
	table.sort( widgets, function( widgetA, widgetB )
		return widgetA:GetPriorityClass() > widgetB:GetPriorityClass()
	end )
	
	-- Регистрация и инициализация каждого переданного виджета
	for _, widget in ipairs( widgets ) do
		if widget and InstanceOf( widget, _G.WidgetClassInterface ) then
			self._widgets[ widget:GetWidgetName() ] = widget
			
			-- Вызывает внутренний Init виджета.
			if widget.Init then
				widget:Init( self._context )
			end
		else
			-- Исключение на соответствие обязательному интерфейсу
			local objectClass = GetParentClass( widget )
			local className = GetClassName( objectClass )
			
			error( string.format( 
				"Unsupported class '%s' does not have an interface 'WidgetClassInterface'", 
				className 
			) )
		end
	end
end

--------------------------------------------------------------------------------
--- Получить ссылку на главную форму аддона.
--- @return userdata
--------------------------------------------------------------------------------
function AlchemyWidgetManager:GetMainForm()
	return self._mainForm
end

--------------------------------------------------------------------------------
--- Получить зарегистрированную обертку виджета по его имени.
--- @param widgetName string
--- @return table | nil -- WidgetClassInterface
--------------------------------------------------------------------------------
function AlchemyWidgetManager:GetWidgetWrapper( widgetName )
	return self._widgets[ widgetName ] or nil
end

--------------------------------------------------------------------------------
-- Показать главную форму аддона.
--------------------------------------------------------------------------------
function AlchemyWidgetManager:Show() --- void
	self._mainForm:Show( true )
end

--------------------------------------------------------------------------------
-- Скрыть главную форму аддона.
--------------------------------------------------------------------------------
function AlchemyWidgetManager:Hide() --- void
	self._mainForm:Show( false )
end