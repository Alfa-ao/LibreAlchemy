for eventName, callable in pairs( _G.LibreAlchemy.events ) do
	common.RegisterEventHandler( callable, eventName )
end

if avatar.IsExist() then -- если аватар загружен в игре то немедленно исполнить:
	_G.LibreAlchemy.events.EVENT_AVATAR_CREATED( { id = avatar.GetId() } )
end

--log( _G )