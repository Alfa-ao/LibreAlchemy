-- UI/Widgets/WidgetOuText.lua

Class( "WidgetOuText", WidgetClassInterface() )

function WidgetOuText:Init( widgetManager )
    self._widget = widgetManager:GetMainForm():GetChildChecked( "ouText" )
    
    local pco = common.GetPosConverterParams()
    local plc = self._widget:GetPlacementPlain()
    plc.posX = pco.fullVirtualSizeX / 2 - 360
    plc.posY = pco.fullVirtualSizeY - plc.posY -- https://github.com/Alfa-ao/LibreAlchemy/issues/1
    self._widget:SetPlacementPlain( plc )
end

-- Метод установки текста
function WidgetOuText:SetValuedText( valuedText )
	self._widget:SetValuedText( valuedText )
end

-- Прямой геттер нативного виджета (если нужен для специфичных операций)
function WidgetOuText:GetWidget()
    return self._widget
end

function WidgetOuText:GetWidgetName()
    return "ouText"
end