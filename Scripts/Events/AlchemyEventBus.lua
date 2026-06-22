-- AlchemyEventBus.lua
-- Единое место регистрации всех событий.

Class( "AlchemyEventBus", {
    _handlers = {},
})

function AlchemyEventBus:Init( ... )
	self._handlers = { ... }
end

function AlchemyEventBus:RegisterAll()
    for _, handler in ipairs( self._handlers ) do
        local eventMap = handler:GetEventMap() 
        
        for eventName, method in pairs( eventMap ) do
            common.RegisterEventHandler( function( ... )
                return method( handler, ... )
            end, eventName )
        end
    end
end