--------------------------------------------------------------------------------
-- Scripts/Services/AlchemyTextContainerService.lua
-- Сервис для управления текстовым контейнером (TextContainer).
--------------------------------------------------------------------------------

Class( "AlchemyTextContainerService", {
    _wtParent  = nil,
    _wtTextContainer = nil,
    _options  = nil,
} )

--------------------------------------------------------------------------------
--- Инициализация сервиса.
--------------------------------------------------------------------------------
function AlchemyTextContainerService:Init( params )
    params = type( params ) == "table" and params or {}
    
    self._wtParent = self._wtTextContainer:GetParent()
    
    self._options = {
        sizePadding = type( params.sizePadding ) == "number" and params.sizePadding > 1 and params.sizePadding or 15
    }
end

--------------------------------------------------------------------------------
--- Установить набор строк в текстовый контейнер.
--- Полностью очищает контейнер перед добавлением новых строк.
--- @param ... ValuedText | WString | string
--------------------------------------------------------------------------------
function AlchemyTextContainerService:SetLines( ... )
    self._wtTextContainer:RemoveItems()
	
	for _, line in ipairs { ... }  do
		self._wtTextContainer:PushBackText( line )
	end
	
    -- Выдать высоту текста и подстроить под него сам Panel
    local exactHeight = self:GetExactTextHeight()
    self:UpdateSizePanel( exactHeight )
end

--------------------------------------------------------------------------------
--- Динамически подстраивает размер Panel под переданную высоту текста + отступы.
--- @param textHeight number
--------------------------------------------------------------------------------
function AlchemyTextContainerService:UpdateSizePanel( textHeight )
    -- Новый отступ от Panel для ouText
    local ouTextPlc = self._wtTextContainer:GetPlacementPlain()
    ouTextPlc.posX = self._options.sizePadding
    ouTextPlc.posY = self._options.sizePadding
    self._wtTextContainer:SetPlacementPlain( ouTextPlc )
    
    -- Ширина: отступ слева (posX) и справа + фиксированная ширина текста
    local targetSizeX = self._options.sizePadding * 2 + ouTextPlc.sizeX
    -- Высота: отступ сверху (posY) и снизу + высота текста
    local targetSizeY = self._options.sizePadding * 2 + textHeight

    -- Новый размер для Panel
    local panelPlc = self._wtParent:GetPlacementPlain()
    panelPlc.sizeX = targetSizeX
    panelPlc.sizeY = targetSizeY
    self._wtParent:SetPlacementPlain( panelPlc )
end

--------------------------------------------------------------------------------
--- Возвращает пиксельную высоту текстового контента.
--- Использует внутренний ouText -> __Border -> __Content.
--- @return number
--------------------------------------------------------------------------------
function AlchemyTextContainerService:GetExactTextHeight()
    self._wtTextContainer:ForceReposition()
    
    local content = self._wtTextContainer:GetChildChecked( "__Border" ):GetChildChecked( "__Content" )
    local contentPlc = content:GetPlacementPlain()
    return contentPlc.posY + contentPlc.sizeY
end

--------------------------------------------------------------------------------
--- Центрирует окно с подсказкой.
--------------------------------------------------------------------------------
function AlchemyTextContainerService:UpdateCenterPanel()
    local pco = common.GetPosConverterParams()
    local plc = self._wtPanel:GetPlacementPlain()

    -- Центрируем панель по горизонтали
    plc.posX = pco.fullVirtualSizeX / 2 - CONFIG.GUI.PANEL_HALF_WIDTH - CONFIG.GUI.PANEL_OFFSET_X
    -- Инвертируем координату Y для корректного отображения относительно верха экрана
    -- Подробности: https://github.com/Alfa-ao/LibreAlchemyV2/issues/1
    plc.posY = pco.fullVirtualSizeY - plc.posY -- Переделать потом на основании окна алхимки

    self._wtPanel:SetPlacementPlain( plc )
end