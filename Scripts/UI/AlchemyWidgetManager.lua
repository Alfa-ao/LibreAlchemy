--------------------------------------------------------------------------------
-- Scripts/UI/AlchemyWidgetManager.lua
-- Менеджер виджетов аддона (AlchemyWidgetManager).
--------------------------------------------------------------------------------

Class( "AlchemyWidgetManager", {
	_mainForm = nil,  -- Ссылка на главную форму аддона (mainForm).
	_widgets = nil,   -- Хеш-таблица зарегистрированных виджетов-оберток { ["widgetName"] = WidgetClassInterface }.
	_services = nil   -- Сервисы
} )

--------------------------------------------------------------------------------
--- Инициализация менеджера виджетов.
--- Принимает произвольное количество экземпляров виджетов, сортирует их по
--- приоритету инициализации и регистрирует в менеджере.
--- @param widgets table WidgetClassInterface
--- @param services table Сервисы
--------------------------------------------------------------------------------
function AlchemyWidgetManager:Init( widgets, services ) --- void
	self._mainForm = _G.mainForm
	self._widgets = {}
	self._services = services
	
	-- Сортировка виджетов по убыванию приоритета (чем больше число, тем раньше инициализируется)
	table.sort( widgets, function( widgetA, widgetB )
		return widgetA:GetPriorityClass() > widgetB:GetPriorityClass()
	end )
	
	-- Регистрация и инициализация каждого переданного виджета
	for _, widget in ipairs( widgets ) do
		if widget and InstanceOf( widget, _G.WidgetClassInterface ) then
			local widgetName = widget:GetWidgetName()
			self._widgets[ widgetName ] = widget
			
			-- Вызываем внутренний Init виджета, передавая ему ссылку на менеджер
			if widget.Init then
				widget:Init( self )
			end
		else
			-- Ругаемся на соответствие обязательному интерфейсу
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
--- Получить сервисы.
--- @return table
--------------------------------------------------------------------------------
function AlchemyWidgetManager:GetServices()
	return self._services
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