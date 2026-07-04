--------------------------------------------------------------------------------
-- Events/AlchemyAvatarEvents.lua
-- Класс, отвечающий за обработку глобальных событий персонажа (EVENT_AVATAR_*).
-- Реализует реакцию на создание аватара (инициализация UI, локализации)
-- и получение предметов (отображение сообщения о успешном создании зелья).
--------------------------------------------------------------------------------

Class( "AlchemyAvatarEvents", EventClassInterface() )

--------------------------------------------------------------------------------
-- Инициализация
--------------------------------------------------------------------------------
function AlchemyAvatarEvents:Init( state, config, widgetMgr, textFmt, services ) --- void
    self._state    = state      -- AlchemyState - глобальное состояние аддона.
    self._config   = config     -- AlchemyConfig - конфигурация аддона.
    self._ui       = widgetMgr  -- AlchemyWidgetManager - менеджер UI виджетов.
    self._text     = textFmt    -- AlchemyTextFormatter - форматировщик текста.
    self._services = services   -- table - набор сервисов (debug, locale, recipe и т.д.).
end

--------------------------------------------------------------------------------
-- Маппинг событий
--------------------------------------------------------------------------------

-- Возвращает таблицу соответствия имен событий методам-обработчикам.
-- Используется AlchemyEventManager для автоматической регистрации.
function AlchemyAvatarEvents:GetEventMap() --- table
    return {
        EVENT_AVATAR_CREATED    = self.OnAvatarCreated, -- Событие создания/входа персонажа.
        EVENT_AVATAR_ITEM_TAKEN = self.OnItemTaken,     -- Событие получения предмета в инвентарь.
    }
end

--------------------------------------------------------------------------------
-- Обработчики событий
--------------------------------------------------------------------------------

-- Обработчик события EVENT_AVATAR_CREATED.
-- Выполняется при входе персонажа в мир. Инициализирует локализацию и кастомный UI.
function AlchemyAvatarEvents:OnAvatarCreated() --- void
    -- Инициализация сервиса локализации (подгрузка нужного языкового пакета).
    self._services.locale:Init()
    
    -- Применение кастомного расположения элементов окна алхимии (если включено в конфиге).
    if self._config.ENABLE_CUSTOM_LAYOUT then
        self._ui:GetWidgetWrapper( "AlchemyV2" ):InitCustomLayout()
    end
    
    -- Попытка инициализации библиотеки Drag&Drop для перетаскивания окна.
    local dndWidgetWrapper = self._ui:GetWidgetWrapper( "Drag&Drop" )
    
    if not dndWidgetWrapper or not dndWidgetWrapper:InitDragAndDrop() then
        -- Сохраним до лучших времен:
        -- self._text:SetText( self._services.locale:Get( "INSTALL_LIB_DND" ) )
        -- self._state.messageType = self._config.MESSAGE_WARNING
    end
end

--------------------------------------------------------------------------------

-- Обработчик события EVENT_AVATAR_ITEM_TAKEN.
-- Срабатывает при получении предмета. Если это результат крафта (алхимии),
-- и реакция была успешной, выводит поздравление с названием и количеством зелий.
function AlchemyAvatarEvents:OnItemTaken( params ) --- void
    self._services.debug:LogGeneral( "EVENT_AVATAR_ITEM_TAKEN" )

    -- params.actionType == "ENUM_TakeItemActionType_Craft" означает, что предмет создан (скрафчен).
    -- self._state.reactionSuccess гарантирует, что мы находимся в процессе/результате алхимии.
    if params.actionType == "ENUM_TakeItemActionType_Craft" and self._state.reactionSuccess then
        -- Получаем информацию о созданном предмете по его ID.
        local info = itemLib.GetItemInfo( params.itemObject:GetId() )
        local potionName = userMods.FromWString( info.name ) -- Конвертируем WString в Lua string.
        
        -- Получаем количество предметов в стаке.
        local count = itemLib.GetStackInfo( params.itemObject:GetId() ).count
        
        -- Формируем и выводим локализованное сообщение о получении предмета.
        self._text:SetText( {
            self._services.locale:Get( "AVATAR_ITEM_TAKEN" ),
            string.format( "[%s]x%d", potionName, count ),
        } )
    end
end