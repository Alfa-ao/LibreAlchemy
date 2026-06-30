-- Events/AlchemyAvatarEvents.lua
-- Класс отвечающий за события EVENT_AVATAR_*.

Class( "AlchemyAvatarEvents", EventClassInterface() )

function AlchemyAvatarEvents:Init( state, config, widgetMgr, textFmt, services ) --- void
    self._state    = state
    self._config   = config
    self._ui       = widgetMgr
    self._text     = textFmt
	self._services = services
end

function AlchemyAvatarEvents:GetEventMap() --- table
    return {
		EVENT_AVATAR_CREATED    = self.OnAvatarCreated,
		EVENT_AVATAR_ITEM_TAKEN = self.OnItemTaken,
    }
end

function AlchemyAvatarEvents:OnAvatarCreated() --- void
    self._services.locale:Init()
    
    if self._config.ENABLE_CUSTOM_LAYOUT then
        self._ui:GetWidgetWrapper( "rollsBar" ):InitCustomLayout()
    end
    
    local dndWidgetWrapper = self._ui:GetWidgetWrapper( "dnd" )
    
    if not dndWidgetWrapper or not dndWidgetWrapper:InitDragAndDrop() then
        -- Сохраним до лучших времен:
        -- self._text:SetText( self._services.locale:Get( "INSTALL_LIB_DND" ) )
        -- self._state.messageType = self._config.MESSAGE_WARNING
    end
end

function AlchemyAvatarEvents:OnItemTaken( params ) --- void
    self._services.debug:LogGeneral( "EVENT_AVATAR_ITEM_TAKEN" )

    if params.actionType == "ENUM_TakeItemActionType_Craft" and self._state.reactionSuccess then
        local info = itemLib.GetItemInfo( params.itemObject:GetId() )
        local potionName = userMods.FromWString( info.name )
        local count = itemLib.GetStackInfo( params.itemObject:GetId() ).count
        self._text:SetText( string.format( self._services.locale:Get( "AVATAR_ITEM_TAKEN" ), potionName, count ) )
    end
end