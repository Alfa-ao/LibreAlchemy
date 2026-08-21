--------------------------------------------------------------------------------
-- Events/AlchemyAvatarEvents.lua
-- Класс, отвечающий за обработку событий персонажа (EVENT_AVATAR_*).
--------------------------------------------------------------------------------

Class( "AlchemyAvatarEvents" )

--------------------------------------------------------------------------------
--- @param context table -- Набор всякого всяческого
--------------------------------------------------------------------------------
function AlchemyAvatarEvents:Init( context )
    self._state          = context.state
    self._classAlchemyV2 = context.AlchemyV2
    self._textContainer  = context.textContainer
    self._debug          = context.debug
    self._locale         = context.locale
    self._dnd            = context.dnd
end

--------------------------------------------------------------------------------
--- Обработчик события EVENT_AVATAR_CREATED.
--- Выполняется при входе персонажа в игру.
--------------------------------------------------------------------------------
function AlchemyAvatarEvents:OnAvatarCreated()
    local wtPanel = _G.mainForm:GetChildChecked( "Panel" )

    -- Получаем параметры виртуального экрана
    local pco = common.GetPosConverterParams()
    local plc = wtPanel:GetPlacementPlain()

    -- Центрируем панель по горизонтали
    plc.posX = pco.fullVirtualSizeX / 2 - 360 - 15
    -- Инвертируем координату Y для корректного отображения относительно верха экрана
    -- Подробности: https://github.com/Alfa-ao/LibreAlchemyV2/issues/1
    plc.posY = pco.fullVirtualSizeY - plc.posY -- Переделать потом на основании окна алхимки

    wtPanel:SetPlacementPlain( plc )
    
    if CONFIG.ENABLE_CUSTOM_LAYOUT then
        -- Применение кастомного расположения элементов окна алхимии.
        self._classAlchemyV2:InitCustomLayout()
    end
    
    -- Окно с подсказкой становится перетаскиваемым.
    self._dnd:Register( wtPanel, { saveToConfig = true } )
end

--------------------------------------------------------------------------------
--- Обработчик события EVENT_AVATAR_ITEM_TAKEN.
--- Срабатывает при получении предмета. Если это действие (крафта),
--- и реакция была успешной, выводит поздравление с названием и количеством зелий.
--- @param params table { actionType: string, itemObject: ValuedObject }
--------------------------------------------------------------------------------
function AlchemyAvatarEvents:OnItemTaken( params )
    self._debug:LogGeneral( "EVENT_AVATAR_ITEM_TAKEN" )
    
    if params.actionType == EnumTakeItemActionType.CRAFT and self._state.reactionSuccess then
        -- Информация о созданном предмете по его ID.
        local info = itemLib.GetItemInfo( params.itemObject:GetId() )
        local potionName = userMods.FromWString( info.name ) -- ПЕРЕДЕЛАТЬ
        
        -- Количество предметов в стаке.
        local count = itemLib.GetStackInfo( params.itemObject:GetId() ).count
        
        self._textContainer:SetLines( 
            self._locale:Get( "AVATAR_ITEM_TAKEN" ), -- WString("Поздравляю! Вы получаете:") -- ПЕРЕДЕЛАТЬ
            string.format( "[%s]x%d", potionName, count ) -- ПЕРЕДЕЛАТЬ
        )
        
        error( "REWORK" )
    end
end