-- AlchemyBootstrap.lua

Class( "AlchemyBootstrap", {
    _eventManager = nil,
} )

function AlchemyBootstrap:Init( eventManager )
    self._eventManager = eventManager
end

function AlchemyBootstrap:Run()
    if avatar.IsExist() then
        self._eventManager:Dispatch( "EVENT_AVATAR_CREATED", { id = avatar.GetId() } )
    end
end