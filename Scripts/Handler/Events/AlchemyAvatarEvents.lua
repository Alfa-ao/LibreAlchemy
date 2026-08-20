--------------------------------------------------------------------------------
-- Handler/Events/AlchemyAvatarEvents.lua
-- Класс, отвечающий за обработку глобальных событий персонажа (EVENT_AVATAR_*).
--------------------------------------------------------------------------------

Class( "AlchemyAvatarEvents", EventClassInterface() )

--------------------------------------------------------------------------------
--- @param context table AlchemyContext
--------------------------------------------------------------------------------
function AlchemyAvatarEvents:Init( context ) --- void
    self._state    = context:GetState()         -- AlchemyState
    self._config   = context:GetConfig()        -- AlchemyConfig
    self._ui       = context:GetWidgetManager() -- AlchemyWidgetManager
    self._text     = context:GetTextFormatter() -- AlchemyTextFormatter
    self._services = context:GetServices()      -- Cервисы
end

--------------------------------------------------------------------------------
--- Маппинг событий
--- Возвращает таблицу соответствия имен событий методам-обработчикам.
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
--- Обработчик события EVENT_AVATAR_CREATED.
--- Выполняется при входе персонажа в игру.
--------------------------------------------------------------------------------
function AlchemyAvatarEvents:OnAvatarCreated() --- void
    if self._config.ENABLE_CUSTOM_LAYOUT then
        -- Применение кастомного расположения элементов окна алхимии.
        self._ui:GetWidgetWrapper( "AlchemyV2" ):InitCustomLayout()
    end
    
    local panelWrapper = self._ui:GetWidgetWrapper( "panel" )
    -- Окно с подсказкой становится перетаскиваемым.
    self._services.dnd:Register( panelWrapper:GetNativeWidget(), { saveToConfig = true } )
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
        -- Информация о созданном предмете по его ID.
        local info = itemLib.GetItemInfo( params.itemObject:GetId() )
        local potionName = userMods.FromWString( info.name )
        
        -- Количество предметов в стаке.
        local count = itemLib.GetStackInfo( params.itemObject:GetId() ).count
        
        -- Формирует и выводит локализованное сообщение о получении предмета.
        self._text:SetText( 
            self._services.locale:Get( "AVATAR_ITEM_TAKEN" ), -- WString("Поздравляю! Вы получаете:")
            string.format( "[%s]x%d", potionName, count )
        )
        
        -- reactionSuccess = false не нужен.
        -- Иначе конфликт между получением и возможных рецептов при:
        -- EVENT_ALCHEMY_ITEM_PLACED
    end
end