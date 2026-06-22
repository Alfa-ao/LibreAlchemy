if rawget( _G, "Facade" ) then
	Global( "log", _G.Facade.customAO.log ) -- var_dump.
	
	local userMods = Facade.AO.userMods
else
	Global( "log", function( ... ) end )
end