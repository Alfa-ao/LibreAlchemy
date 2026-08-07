--------------------------------------------------------------------------------
-- Events/AlchemyPosEvents.lua
-- Класс, отвечающий за обработку событий (EVENT_POS_*).
--------------------------------------------------------------------------------

Class( "AlchemyPosEvents", EventClassInterface() )

--------------------------------------------------------------------------------
--- Инициализация
--- @param state table AlchemyState
--- @param config table AlchemyConfig
--- @param widgetMgr table AlchemyWidgetManager
--- @param services table Services
--------------------------------------------------------------------------------
function AlchemyPosEvents:Init( state, config, widgetMgr, textFormatter, services ) --- void
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
function AlchemyPosEvents:GetEventMap()
    return {
        EVENT_POS_CONVERTER_CHANGED = self.OnPosConverterChanged,
    }
end

--------------------------------------------------------------------------------
-- Обработчики событий
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Обработчик события EVENT_POS_CONVERTER_CHANGED.
-- Уведомление об изменении игрового окна.
--------------------------------------------------------------------------------
function AlchemyPosEvents:OnPosConverterChanged() --- void
    ----------------------------------------
    self._services.debug:LogGeneral( "EVENT_POS_CONVERTER_CHANGED" )
    ----------------------------------------

    self._services.dnd:OnPosConverterChanged()
end