-- Services/AlchemyLocaleService.lua

Class( "AlchemyLocaleService", {
    _group = nil,
})

function AlchemyLocaleService:Init() --- void
    self._group = common.GetAddonRelatedTextGroup(
        common.GetLocalization(), true
    ) or common.GetAddonRelatedTextGroup( "eng" )
end

function AlchemyLocaleService:Get( key ) --- string
    if self._group and self._group:HasText( key ) then
        return userMods.FromWString( self._group:GetText( key ) )
    end
	
    error( string.format( "AlchemyLocaleService: Locale key '%s' not found in text group.", tostring( key ) ), 2 )
end