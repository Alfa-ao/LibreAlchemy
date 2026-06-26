-- AlchemyWidgetManager.lua

Class( "AlchemyWidgetManager", {
    _mainForm = nil,
    _ouText = nil,
})

function AlchemyWidgetManager:Init()
    self._mainForm = _G.mainForm
    self._ouText = self._mainForm:GetChildChecked( "ouText" )
    
    local pco = common.GetPosConverterParams()
    local plc = self._ouText:GetPlacementPlain()
    plc.posX = pco.fullVirtualSizeX / 2 - 360
    plc.posY = pco.fullVirtualSizeY - plc.posY -- https://github.com/Alfa-ao/LibreAlchemy/issues/1
    self._ouText:SetPlacementPlain( plc )
    
    self:Hide()
end

function AlchemyWidgetManager:InitDragAndDrop()
    if rawget( _G, "DnD" ) then
        _G.DnD.Init( self._ouText, nil, true )
        return true
    end
    
    return false
end

function AlchemyWidgetManager:Show() self._mainForm:Show( true ) end
function AlchemyWidgetManager:Hide() self._mainForm:Show( false ) end
function AlchemyWidgetManager:GetTextWidget() return self._ouText end