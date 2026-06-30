-- Events/EventClassInterface.lua

Class( "EventClassInterface", {
    _state  = nil,
    _config = nil,
} )

function EventClassInterface:GetEventMap() --- table
    error( "EventClassInterface:GetEventMap must be implemented by subclass" )
end