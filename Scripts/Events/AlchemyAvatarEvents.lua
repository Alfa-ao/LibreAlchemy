--------------------------------------------------------------------------------
-- Events/AlchemyAvatarEvents.lua
-- Класс, отвечающий за обработку глобальных событий персонажа (EVENT_AVATAR_*).
-- Реализует реакцию на создание аватара и получение предметов 
-- (отображение сообщения о успешном создании зелья).
--------------------------------------------------------------------------------

Class( "AlchemyAvatarEvents", EventClassInterface() )

--------------------------------------------------------------------------------
--- Инициализация
--- @param state table AlchemyState
--- @param config table AlchemyConfig
--- @param widgetMgr table AlchemyWidgetManager
--- @param textFmt table AlchemyTextFormatter
--- @param services table Services
--------------------------------------------------------------------------------
function AlchemyAvatarEvents:Init( state, config, widgetMgr, textFmt, services ) --- void
    self._state    = state      -- AlchemyState - глобальное состояние аддона.
    self._config   = config     -- AlchemyConfig - конфигурация аддона.
    self._ui       = widgetMgr  -- AlchemyWidgetManager - менеджер UI виджетов.
    self._text     = textFmt    -- AlchemyTextFormatter - форматировщик текста.
    self._services = services   -- table - сервисы.
end

--------------------------------------------------------------------------------
--- Маппинг событий
--- Возвращает таблицу соответствия имен событий методам-обработчикам.
--- Используется AlchemyEventManager для автоматической регистрации.
--- @return table
--------------------------------------------------------------------------------
function AlchemyAvatarEvents:GetEventMap()
    return {
        EVENT_AVATAR_CREATED    = self.OnAvatarCreated, -- Событие создания/входа персонажа.
        EVENT_AVATAR_ITEM_TAKEN = self.OnItemTaken,     -- Событие получения предмета в инвентарь.
    }
end

--------------------------------------------------------------------------------
-- Обработчики событий
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Обработчик события EVENT_AVATAR_CREATED.
-- Выполняется при входе персонажа в игру. 
-- Инициализирует кастомный UI.
--------------------------------------------------------------------------------
function AlchemyAvatarEvents:OnAvatarCreated() --- void
    -- Применение кастомного расположения элементов окна алхимии (если включено в конфиге).
    if self._config.ENABLE_CUSTOM_LAYOUT then
        self._ui:GetWidgetWrapper( "AlchemyV2" ):InitCustomLayout()
    end
    
    -- Попытка инициализации библиотеки Drag&Drop для перетаскивания окна.
    local dndWidgetWrapper = self._ui:GetWidgetWrapper( "dnd" )
    
    if not dndWidgetWrapper or not dndWidgetWrapper:InitDragAndDrop() then
        -- Сохраним до лучших времен:
        -- self._text:SetText( self._services.locale:Get( "INSTALL_LIB_DND" ) )
        -- self._state.messageType = self._config.MESSAGE_WARNING
    end
end

--------------------------------------------------------------------------------
--- Обработчик события EVENT_AVATAR_ITEM_TAKEN.
--- Срабатывает при получении предмета. Если это действие (крафта),
--- и реакция была успешной, выводит поздравление с названием и количеством зелий.
--- @param params table { actionType: string, itemObject: ValuedObject }
--------------------------------------------------------------------------------
function AlchemyAvatarEvents:OnItemTaken( params ) --- void
    self._services.debug:LogGeneral( "EVENT_AVATAR_ITEM_TAKEN" )

    -- params.actionType == "ENUM_TakeItemActionType_Craft" предмет (скрафчен).
    -- self._state.reactionSuccess результат варки успешен ?
    if params.actionType == EnumTakeItemActionType.CRAFT and self._state.reactionSuccess then
        -- Получаем информацию о созданном предмете по его ID.
        local info = itemLib.GetItemInfo( params.itemObject:GetId() )
        local potionName = userMods.FromWString( info.name )
        
        -- Получаем количество предметов в стаке.
        local count = itemLib.GetStackInfo( params.itemObject:GetId() ).count
        
        -- Формируем и выводим локализованное сообщение о получении предмета.
        self._text:SetText( 
            self._services.locale:Get( "AVATAR_ITEM_TAKEN" ), -- WString("Поздравляю! Вы получаете:")
            string.format( "[%s]x%d", potionName, count )
        )
        
        -- reactionSuccess = false не нужен.
        -- Иначе конфликт между получением и возможных рецептов при:
        -- EVENT_ALCHEMY_ITEM_PLACED
    end
end