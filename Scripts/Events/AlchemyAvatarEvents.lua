-- AlchemyAvatarEvents.lua
-- Класс отвечающий за события EVENT_AVATAR_*.

Class( "AlchemyAvatarEvents", {
    _state    = nil,
    _config   = nil,
    _ui       = nil,
    _text     = nil,
	_services = {},
} )

function AlchemyAvatarEvents:Init( state, config, widgetMgr, textFmt, services )
    self._state    = state
    self._config   = config
    self._ui       = widgetMgr
    self._text     = textFmt
	self._services = services
end

function AlchemyAvatarEvents:GetEventMap()
    return {
		EVENT_AVATAR_CREATED    = self.OnAvatarCreated,
		EVENT_AVATAR_ITEM_TAKEN = self.OnItemTaken,
    }
end

function AlchemyAvatarEvents:OnAvatarCreated()
    self._services.locale:Init()
    self._ui:Init()

    if not self._ui:InitDragAndDrop() then
        --self._text:SetText( self._services.locale:Get( "INSTALL_LIB_DND" ) )
        --self._state.messageType = self._config.MESSAGE_WARNING
    end
end

function AlchemyAvatarEvents:OnItemTaken( params )
    self._services.debug:LogGeneral( "EVENT_AVATAR_ITEM_TAKEN" )

    if params.actionType == "ENUM_TakeItemActionType_Craft" and self._state.reactionSuccess then
        local info = itemLib.GetItemInfo( params.itemObject:GetId() )
        local potionName = userMods.FromWString( info.name )
        local count = itemLib.GetStackInfo( params.itemObject:GetId() ).count
        self._text:SetText( string.format( self._services.locale:Get( "AVATAR_ITEM_TAKEN" ), potionName, count ) )
    end
end