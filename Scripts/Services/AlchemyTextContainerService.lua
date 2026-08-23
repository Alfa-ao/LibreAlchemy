--------------------------------------------------------------------------------
-- Scripts/Services/AlchemyTextContainerService.lua
-- Сервис для управления текстовым контейнером (TextContainer).
--------------------------------------------------------------------------------

Class( "AlchemyTextContainerService" )

--------------------------------------------------------------------------------
--- Инициализация сервиса.
--------------------------------------------------------------------------------
function AlchemyTextContainerService:Init()
    self._wtPanel = _G.mainForm:GetChildChecked( "Panel" )
    self._wtOuText = self._wtPanel:GetChildChecked( "ouText" )
end

--------------------------------------------------------------------------------
--- Установить набор строк в текстовый контейнер.
--- Полностью очищает контейнер перед добавлением новых строк.
--- @param ... ValuedText | WString | string
--------------------------------------------------------------------------------
function AlchemyTextContainerService:SetLines( ... )
	local linesArray = { ... }
    
    self._wtOuText:RemoveItems()
	
	for _, line in ipairs( linesArray ) do
		self._wtOuText:PushBackText( line )
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
    local padding = 15 -- Говнокод убрать в конфиг
    
    local ouTextPlc = self._wtOuText:GetPlacementPlain()
    
    -- Ширина: отступ слева (posX) + фиксированная ширина текста (sizeX) + отступ справа
    local targetSizeX = ouTextPlc.posX + ouTextPlc.sizeX + padding
    -- Высота: отступ сверху (posY) + (fontsize="15") высота текста + отступ снизу
    local targetSizeY = ouTextPlc.posY + textHeight + padding

    -- Новый размер для Panel
    local panelPlc = self._wtPanel:GetPlacementPlain()
    panelPlc.sizeX = targetSizeX
    panelPlc.sizeY = targetSizeY
    self._wtPanel:SetPlacementPlain( panelPlc )
end

--------------------------------------------------------------------------------
--- Возвращает пиксельную высоту текстового контента.
--- Использует внутренний ouText -> __Border -> __Content.
--- @return number
--------------------------------------------------------------------------------
function AlchemyTextContainerService:GetExactTextHeight()
    self._wtOuText:ForceReposition()
    
    local content = self._wtOuText:GetChildChecked( "__Border" ):GetChildChecked( "__Content" )
    local contentPlc = content:GetPlacementPlain()
    return contentPlc.posY + contentPlc.sizeY
end