--------------------------------------------------------------------------------
-- Инициализация интерфейса
--------------------------------------------------------------------------------

--- @function _G.LibreAlchemy.fn.InitWidgets
--- @description Инициализирует ссылки на виджеты интерфейса и настраивает их начальное расположение.
_G.LibreAlchemy.fn.InitWidgets = function()
	_G.LibreAlchemy.widgets.ouText = _G.mainForm:GetChildChecked( "ouText" )
	
	local pco = common.GetPosConverterParams()
	local plc = _G.LibreAlchemy.widgets.ouText:GetPlacementPlain()
	
	-- Задаем позицию по X (сдвиг от левого края)
	plc.posX = pco.fullVirtualSizeX / 2 - 360
	-- Применяем параметры размещения для вложенной панели
	_G.LibreAlchemy.widgets.ouText:SetPlacementPlain( plc )
	
	-- Drag&Drop
	DnD.Init( _G.LibreAlchemy.widgets.ouText, nil, true )
	
	-- Facade.customAO.logInfo( Facade.customAO.getWidgetTree( "AlchemyV2" ) )
	
	-- _G.mainForm:Show( true )
	-- _G.LibreAlchemy.fn.wSetText( "Test Test TEXT QWERTY" )
end
