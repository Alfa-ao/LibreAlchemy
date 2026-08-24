--------------------------------------------------------------------------------
-- GUI/WidgetAlchemyV2.lua
-- Обертка для кастомизации стандартного интерфейса окна алхимии.
-- Изменяет размеры и позиции стандартных элементов (колб, кнопок, горелок).
--------------------------------------------------------------------------------

Class( "WidgetAlchemyV2", {
    _wtRolls = nil,
    _wtRecipeName = nil,
} )

--------------------------------------------------------------------------------
-- Новый стиль окна с барабанами для Алхимки
--------------------------------------------------------------------------------
function WidgetAlchemyV2:InitCustomLayout()
    local listBars = {
        self._wtRolls:GetChildChecked( "Bar01" ),
        self._wtRolls:GetChildChecked( "Bar02" ),
        self._wtRolls:GetChildChecked( "Bar03" ),
        self._wtRolls:GetChildChecked( "Bar04" ),
        self._wtRolls:GetChildChecked( "Bar05" ),
    }
    
    -- Bar(01/02/03/04/05).RollTube.(ActionUp/ActionDown)
    for _, bar in ipairs( listBars ) do
        local rollTube = bar:GetChildChecked( "RollTube" )
        
        -- Отвечает за: Позицию верхней кнопки.
        local actionUp = rollTube:GetChildChecked( "ActionUp" )
        local plcActionUp = actionUp:GetPlacementPlain()
        plcActionUp.posY = CONFIG.GUI.ACTION_UP_POS_Y
        actionUp:SetPlacementPlain( plcActionUp )
        
        -- Отвечает за: Позицию нижней кнопки.
        local actionDown = rollTube:GetChildChecked( "ActionDown" )
        local plcActionDown = actionDown:GetPlacementPlain()
        plcActionDown.posY = CONFIG.GUI.ACTION_UP_POS_Y + plcActionDown.sizeY
        actionDown:SetPlacementPlain( plcActionDown )
        
        -- Отвечает за: Размер основной колбы совместно с BackLayer текстурой.
        local plcRollTube = rollTube:GetPlacementPlain()
        plcRollTube.sizeY = CONFIG.GUI.ROLL_TUBE_EXTRA_SIZE + plcActionDown.sizeY
        rollTube:SetPlacementPlain( plcRollTube )
        
        -- Отвечает за: Контейнер (Основная колба + Горелка под колбой)
        local plcBar = bar:GetPlacementPlain()
        plcBar.sizeY = CONFIG.GUI.BAR_EXTRA_SIZE + plcActionDown.sizeY
        bar:SetPlacementPlain( plcBar )
        
        -- Отвечает за: Цифра над горелкой
        local correctionCount = bar:GetChildChecked( "CorrectionCount" )
        local plcCorrectionCount = correctionCount:GetPlacementPlain()
        plcCorrectionCount.sizeY = CONFIG.GUI.CORRECTION_COUNT_EXTRA_SIZE
        correctionCount:SetPlacementPlain( plcCorrectionCount )
    end
    
    -- Отвечает за: Контейнер c 5ю колбами (Иконки над колбой + Основная колба + Горелка под колбой)
    local plcRolls = self._wtRolls:GetPlacementPlain()
    plcRolls.sizeY = CONFIG.GUI.BAR_EXTRA_SIZE + CONFIG.GUI.ROLLS_EXTRA_SIZE
    plcRolls.highPosY = CONFIG.GUI.ROLLS_HIGH_POS_Y_OFFSET - CONFIG.GUI.ROLLS_EXTRA_SIZE
    self._wtRolls:SetPlacementPlain( plcRolls )
end

--------------------------------------------------------------------------------
--- Получить имя рецепта, выбранного в AlchemyV2 (в меню варки).
--- @return WString
--------------------------------------------------------------------------------
function WidgetAlchemyV2:GetCurrentRecipeName()
    return self._wtRecipeName:GetWString()
end