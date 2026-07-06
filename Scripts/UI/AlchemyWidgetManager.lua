--------------------------------------------------------------------------------
-- Scripts/UI/AlchemyWidgetManager.lua
-- Менеджер виджетов аддона (AlchemyWidgetManager).
-- Отвечает за инициализацию, регистрацию и управление жизненным циклом
-- всех кастомных оберток над нативными виджетами (WidgetClassInterface).
--------------------------------------------------------------------------------

Class( "AlchemyWidgetManager", {
	_mainForm = nil,  -- Ссылка на главную форму аддона (mainForm).
	_widgets = {},    -- Хеш-таблица зарегистрированных виджетов-оберток { ["widgetName"] = WidgetClassInterface }.
} )

--------------------------------------------------------------------------------
--- Инициализация менеджера виджетов.
--- Принимает произвольное количество экземпляров виджетов, сортирует их по
--- приоритету инициализации и регистрирует в менеджере.
--- @param ... table WidgetClassInterface
--------------------------------------------------------------------------------
function AlchemyWidgetManager:Init( ... ) --- void
	self._mainForm = _G.mainForm
	self._widgets = {}
	
	local widgets = { ... }
	
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
--- Получить ссылку на главную форму аддона.
--- Используется виджетами для получения доступа к нативному дереву элементов
--- без прямого обращения к глобальной переменной _G.mainForm.
--- @return userdata
--------------------------------------------------------------------------------
function AlchemyWidgetManager:GetMainForm()
	return self._mainForm
end

--------------------------------------------------------------------------------
--- Получить зарегистрированную обертку виджета по его системному имени.
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