--------------------------------------------------------------------------------
-- Events/AlchemyDNDEvents.lua
-- Класс, отвечающий за обработку событий (EVENT_DND_*).
--------------------------------------------------------------------------------

Class( "AlchemyDNDEvents", EventClassInterface() )

--------------------------------------------------------------------------------
--- Инициализация
--- @param state table AlchemyState
--- @param config table AlchemyConfig
--- @param widgetMgr table AlchemyWidgetManager
--- @param services table Services
--------------------------------------------------------------------------------
function AlchemyDNDEvents:Init( state, config, widgetMgr, textFormatter, services ) --- void
    self._state    = state      -- AlchemyState - глобальное состояние аддона.
    self._config   = config     -- AlchemyConfig - конфигурация аддона.
    self._ui       = widgetMgr  -- AlchemyWidgetManager - менеджер UI виджетов.
    self._services = services   -- table - сервисы.
end

--------------------------------------------------------------------------------
--- Маппинг событий.
--- Возвращает таблицу соответствия имен событий методам-обработчикам.
--- Используется AlchemyEventManager для автоматической регистрации.
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