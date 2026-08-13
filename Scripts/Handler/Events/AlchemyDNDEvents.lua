--------------------------------------------------------------------------------
-- Handler/Events/AlchemyDNDEvents.lua
-- Класс, отвечающий за обработку событий (EVENT_DND_*).
--------------------------------------------------------------------------------

Class( "AlchemyDNDEvents", EventClassInterface() )

--------------------------------------------------------------------------------
--- @param context table AlchemyContext
--------------------------------------------------------------------------------
function AlchemyDNDEvents:Init( context ) --- void
    self._services = context:GetServices()   -- Cервисы.
end

--------------------------------------------------------------------------------
--- Маппинг событий.
--- Возвращает таблицу соответствия имен событий методам-обработчикам.
--- @return table
--------------------------------------------------------------------------------
function AlchemyDNDEvents:GetEventMap()
    return {
        EVENT_DND_PICK_ATTEMPT   = self.OnPickAttempt,
        EVENT_DND_DRAG_TO        = self.OnDragTo,
        EVENT_DND_DROP_ATTEMPT   = self.OnDropAttempt,
        EVENT_DND_DRAG_CANCELLED = self.OnDragCancelled,
    }
end

--------------------------------------------------------------------------------
-- Обработчики событий
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Обработчик события EVENT_DND_PICK_ATTEMPT.
--------------------------------------------------------------------------------
function AlchemyDNDEvents:OnPickAttempt( params ) --- void
    ----------------------------------------
    self._services.debug:LogGeneral( "EVENT_DND_PICK_ATTEMPT" )
    ----------------------------------------

    self._services.dnd:OnPickAttempt( params )
end

--------------------------------------------------------------------------------
-- Обработчик события EVENT_DND_DRAG_TO.
--------------------------------------------------------------------------------
function AlchemyDNDEvents:OnDragTo( params ) --- void
    ----------------------------------------
    self._services.debug:LogGeneral( "EVENT_DND_DRAG_TO" )
    ----------------------------------------

    self._services.dnd:OnDragTo( params )
end

--------------------------------------------------------------------------------
-- Обработчик события EVENT_DND_DROP_ATTEMPT.
--------------------------------------------------------------------------------
function AlchemyDNDEvents:OnDropAttempt( params ) --- void
    ----------------------------------------
    self._services.debug:LogGeneral( "EVENT_DND_DROP_ATTEMPT" )
    ----------------------------------------

    self._services.dnd:OnDropAttempt( params )
end

--------------------------------------------------------------------------------
-- Обработчик события EVENT_DND_DRAG_CANCELLED.
--------------------------------------------------------------------------------
function AlchemyDNDEvents:OnDragCancelled() --- void
    ----------------------------------------
    self._services.debug:LogGeneral( "EVENT_DND_DRAG_CANCELLED" )
    ----------------------------------------

    self._services.dnd:OnDragCancelled()
end