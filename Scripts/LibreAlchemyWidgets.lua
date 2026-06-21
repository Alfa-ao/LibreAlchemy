--------------------------------------------------------------------------------
-- Инициализация интерфейса
--------------------------------------------------------------------------------

--- @function _G.LibreAlchemy.fn.InitWidgets
--- @description Инициализирует LibDnD, либо выводит сообщение об его установке.
_G.LibreAlchemy.fn.InitDragAndDrop = function()
	if rawget( _G, "DnD" ) then
		_G.DnD.Init( _G.LibreAlchemy.widgets.ouText, nil, true )
		return
	end
	
	_G.LibreAlchemy.fn.wSetText( _G.LibreAlchemy.locales.INSTALL_LIB_DND )
	_G.LibreAlchemy.messageType = 3
end

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
	
	-- (ПЕРЕНЕСТИ) в EVENT_AVATAR_CREATED
	-- Drag&Drop
	_G.LibreAlchemy.fn.InitDragAndDrop()
	
	--local vt = common.CreateValuedText()
	--vt:SetFormat( userMods.ToWString( [[<html><log fontsize="20"><r name="www" /></log></html>]] ) )
	-- vt:SetVal( "www", "test" )
	-- _G.LibreAlchemy.widgets.ouText:SetValuedText( vt )
	-- _G.mainForm:Show( true )
end
