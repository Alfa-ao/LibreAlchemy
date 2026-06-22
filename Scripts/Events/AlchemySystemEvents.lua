-- AlchemySystemEvents.lua

Class( "AlchemySystemEvents", {
    _state    = nil,
    _config   = nil,
    _text     = nil,
	_services = {},
})

function AlchemySystemEvents:Init( state, config, textFmt, services )
    self._state    = state
    self._config   = config
    self._text     = textFmt
	self._services = services
end

function AlchemySystemEvents:GetEventMap()
    return {
		EVENT_SECOND_TIMER = self.OnSecondTimer,
    }
end

function AlchemySystemEvents:OnSecondTimer()
    if self._state.active and self._state.place.placed == false and avatar.GetAlchemyInfo().active then
        if self._state.place.readyNotFoundMessage then
            self._text:SetText( self._services.locale:Get( "NOT_FOUND_RECIPLES" ) )
            self._state.place.placed = nil
            self._state.place.readyNotFoundMessage = false
        else
            self._state.place.readyNotFoundMessage = true
        end
    end

    if self._state.active then
        self._state.messageType = self._config.MESSAGE_NORMAL
    end
end