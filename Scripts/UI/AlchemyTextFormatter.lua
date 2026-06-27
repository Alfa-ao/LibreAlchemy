-- UI/AlchemyTextFormatter.lua

Class( "AlchemyTextFormatter", {
	_widgetManager = nil,
	_debug         = nil,
} )

function AlchemyTextFormatter:Init( widgetManager, debug )
	self._widgetManager = widgetManager
	self._debug         = debug
end

function AlchemyTextFormatter:SetText( text )
	self._debug:LogGeneral( text )
	local vt = common.CreateValuedText()
	vt:SetFormat( userMods.ToWString( string.format( [[<html><log fontsize="20">%s</log></html>]], text ) ) )
	
	local ouTextWidget = self._widgetManager:GetWidget( "ouText" )
    if ouTextWidget then
        ouTextWidget:SetValuedText( vt )
		return
    end
	
	error( "AlchemyTextFormatter: Widget 'ouText' not found", 2 )
end

-- Форматирует список найденных рецептов для UI
function AlchemyTextFormatter:FormatResults( found, maxDisplay, nDrums )
	table.sort( found, function( a, b )
		if a.recipe.score == b.recipe.score then
			return a.recipe.name > b.recipe.name
		end
		return a.recipe.score > b.recipe.score
	end )
	
	local parts = {}
	for i = 1, math.min( #found, maxDisplay ) do
		local foundResult = found[i]
		local shiftStr = string.format( "% d", -foundResult.shifts[1] )
		
		for drumIndex = 2, nDrums do
			shiftStr = shiftStr .. string.format( " |% d", -foundResult.shifts[drumIndex] )
		end
		
		table.insert( parts, string.format( "%d: %s - %s", foundResult.recipe.score, shiftStr, foundResult.recipe.name ) )
	end
	
	return table.concat( parts, "<br/>" )
end

--- Форматирует для лога
function AlchemyTextFormatter:FormatResultsForLog( found, maxDisplay, nDrums )
	local parts = {}
	
	for i = 1, math.min( #found, maxDisplay ) do
		local foundResult = found[i]
		local logStr = string.format( "%d,%d", foundResult.recipe.score, -foundResult.shifts[1] )
		
		for drumIndex = 2, nDrums do
			logStr = logStr .. string.format( ",%d", -foundResult.shifts[drumIndex] )
		end
		
		logStr = logStr .. "," .. foundResult.recipe.name
		table.insert( parts, logStr )
	end
	
	return "EVENT_ALCHEMY_REACTION_FINISHED:" .. table.concat( parts, "|" )
end