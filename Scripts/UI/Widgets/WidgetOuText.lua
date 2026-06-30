-- UI/Widgets/WidgetOuText.lua

Class( "WidgetOuText", WidgetClassInterface() )

function WidgetOuText:Init( widgetManager ) --- void
    self._widget = widgetManager:GetMainForm():GetChildChecked( "ouText" )
    
    local pco = common.GetPosConverterParams()
    local plc = self._widget:GetPlacementPlain()
    plc.posX = pco.fullVirtualSizeX / 2 - 360
    plc.posY = pco.fullVirtualSizeY - plc.posY -- https://github.com/Alfa-ao/LibreAlchemy/issues/1
    self._widget:SetPlacementPlain( plc )
    
    self._widget:SetVal( 'content', "LibreAlchemyV2" ) -- Присваиваем стандартный текст для решения неких проблем.
end

function WidgetOuText:GetPriorityClass() --- int
	return 10
end

-- Метод присваивания значения
function WidgetOuText:SetVal( tag, value ) --- void
	self._widget:SetVal( tag, value )
end

function WidgetOuText:GetNativeWidget() --- ?Widget
    return self._widget
end

function WidgetOuText:GetWidgetName() --- string
    return "ouText"
end