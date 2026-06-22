-- AlchemyTextFormatter.lua

Class( "AlchemyTextFormatter", {
    _widgetManager = nil,
    _debug         = nil,
})

function AlchemyTextFormatter:Init( widgetManager, debug )
    self._widgetManager = widgetManager
    self._debug         = debug
end

function AlchemyTextFormatter:SetText( text )
    self._debug:LogGeneral( text )
	
    local vt = common.CreateValuedText()
    vt:SetFormat( userMods.ToWString( string.format( [[<html><log fontsize="20">%s</log></html>]], text ) ) )
    self._widgetManager:GetTextWidget():SetValuedText( vt )
end

-- Форматирует список найденных рецептов для UI
function AlchemyTextFormatter:FormatResults( found, maxDisplay, nDrums )
    table.sort( found, function( a, b )
        if a.rc.score == b.rc.score then
            return a.rc.name > b.rc.name
        end
        return a.rc.score > b.rc.score
    end )

    local parts = {}
    for i = 1, math.min( #found, maxDisplay ) do
        local vr = found[i]
        local shiftStr = string.format( "%d", -vr.sh[1] )
        for dc = 2, nDrums do
            shiftStr = shiftStr .. string.format( " |% d", -vr.sh[dc] )
        end
        table.insert( parts, string.format( "%d: %s - %s", vr.rc.score, shiftStr, vr.rc.name ) )
    end

    return table.concat( parts, "<br/>" )
end

--- Форматирует для лога
function AlchemyTextFormatter:FormatResultsForLog( found, maxDisplay, nDrums )
    local parts = { "EVENT_ALCHEMY_REACTION_FINISHED:" }
    for i = 1, math.min( #found, maxDisplay ) do
        local vr = found[i]
        local s = string.format( "%d,%d", vr.rc.score, -vr.sh[1] )
        for dc = 2, nDrums do
            s = s .. string.format( ",%d", -vr.sh[dc] )
        end
        s = s .. "," .. vr.rc.name
        table.insert( parts, s )
    end
    return table.concat( parts, "|" )
end