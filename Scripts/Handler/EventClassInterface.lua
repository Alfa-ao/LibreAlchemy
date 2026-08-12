--------------------------------------------------------------------------------
-- Handler/EventClassInterface.lua
-- Базовый класс-интерфейс для всех обработчиков событий аддона.
--------------------------------------------------------------------------------

Class( "EventClassInterface" )

--------------------------------------------------------------------------------
-- Абстрактные методы (должны быть реализованы в дочерних классах)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- @param context table AlchemyContext
--------------------------------------------------------------------------------
function EventClassInterface:Init( context )
    error( "EventClassInterface:GetEventMap must be implemented by subclass" )
end

--- Возвращает таблицу соответствия имен игровых событий методам-обработчикам.
--- Формат: { [EVENT_NAME] = self.MethodName, ... }
--- @return table
function EventClassInterface:GetEventMap()
    error( "EventClassInterface:GetEventMap must be implemented by subclass" )
end