--------------------------------------------------------------------------------
-- UI/Widgets/WidgetDnD.lua
-- Обертка над виджетом для интеграции с библиотекой Drag & Drop (LibDnD).
--------------------------------------------------------------------------------

Class( "WidgetDnD", WidgetClassInterface() )

--------------------------------------------------------------------------------
--- Инициализация виджета.
--- @param context table - экземпляр класса AlchemyContext
--------------------------------------------------------------------------------
function WidgetDnD:Init( context ) --- void
	self._widgetManager = context:GetWidgetManager()
    self._services      = context:GetServices()
end

--------------------------------------------------------------------------------
--- Инициализировать механизм Drag & Drop для окна с подсказкой.
--- @return boolean
--------------------------------------------------------------------------------
function WidgetDnD:InitDragAndDrop()
    -- Получаем обертку над Panel через менеджер
    local panelWrapper = self._widgetManager:GetWidgetWrapper( "panel" )
    
    if self._services.dnd then
        self._services.dnd:Register( panelWrapper:GetNativeWidget() )
        
        return true
    end
    
    return false
end

--------------------------------------------------------------------------------
--- Получить имя виджета для регистрации в менеджере.
--- @return string
--------------------------------------------------------------------------------
function WidgetDnD:GetWidgetName()
	return "dnd"
end

--------------------------------------------------------------------------------
--- Получить ссылку на связанный объект.
--- @return userdata | table | nil
--------------------------------------------------------------------------------
function WidgetDnD:GetNativeWidget()
	return nil
end
