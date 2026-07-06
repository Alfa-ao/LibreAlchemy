if rawget( _G, "Facade" ) then
	Global( "log", _G.Facade.customAO.log ) -- var_dump.
	
	local userMods = Facade.AO.userMods
else
	Global( "log", function( ... )
		local args = { ... }
		
		for i = 1, #args do
			common.LogInfo( "common", tostring( args[i] ) )
		end
	end )
end