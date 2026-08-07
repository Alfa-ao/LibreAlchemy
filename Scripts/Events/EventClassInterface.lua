--------------------------------------------------------------------------------
-- Events/EventClassInterface.lua
-- Базовый класс-интерфейс для всех обработчиков событий аддона.
-- Определяет контракт, который обязаны реализовать дочерние классы.
-- Служит маркером для AlchemyEventManager: через InstanceOf() проверяется,
-- что переданный обработчик корректно реализует данный интерфейс.
--------------------------------------------------------------------------------

Class( "EventClassInterface", {
    _state  = nil,  -- ?AlchemyState - ссылка на глобальное состояние аддона.
    _config = nil,  -- ?AlchemyConfig - ссылка на конфигурацию аддона.
} )

--------------------------------------------------------------------------------
-- Абстрактные методы (должны быть реализованы в дочерних классах)
--------------------------------------------------------------------------------

--- @param state table AlchemyState
--- @param config table AlchemyConfig
--- @param widgetManager table AlchemyWidgetManager
--- @param textFormatter table AlchemyTextFormatter
--- @param services table Services
function EventClassInterface:Init( state, config, widgetManager, textFormatter, services )
    error( "EventClassInterface:GetEventMap must be implemented by subclass" )
end

--- Возвращает таблицу соответствия имен игровых событий методам-обработчикам.
--- Формат: { [EVENT_NAME] = self.MethodName, ... }
--- Используется AlchemyEventManager для автоматической регистрации через common.RegisterEventHandler.
--- @return table
function EventClassInterface:GetEventMap()
    error( "EventClassInterface:GetEventMap must be implemented by subclass" )
end