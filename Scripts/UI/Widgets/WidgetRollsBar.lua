--------------------------------------------------------------------------------
-- UI/Widgets/WidgetRollsBar.lua
-- Обертка для модификации стандартного интерфейса окна алхимии (RollsBar).
-- Не создает новый виджет, а программно изменяет размеры и позиции нативных
-- элементов (колб, кнопок, горелок) для применения кастомного, более компактного
-- стиля отображения окна варки зелий.
--------------------------------------------------------------------------------

Class( "WidgetRollsBar", WidgetClassInterface() )

-- Новый стиль окна с барабанами для Алхимии
function WidgetRollsBar:InitCustomLayout() --- void
	-- AlchemyV2.MainFrame.Alchemy.Game.View.Rolls
    local rolls = _G.stateMainForm:GetChildChecked( "AlchemyV2" ):GetChildChecked( "Rolls", true )
    
    local bars = {
        rolls:GetChildChecked( "Bar01" ),
        rolls:GetChildChecked( "Bar02" ),
        rolls:GetChildChecked( "Bar03" ),
        rolls:GetChildChecked( "Bar04" ),
        rolls:GetChildChecked( "Bar05" ),
    }
    
    -- Bar(01/02/03/04/05).RollTube.(ActionUp/ActionDown)
    for _, bar in ipairs( bars ) do
        local rollTube = bar:GetChildChecked( "RollTube" )
        
        -- Отвечает за: Позицию верхней кнопки.
        local actionUp = rollTube:GetChildChecked( "ActionUp" )
        local plcActionUp = actionUp:GetPlacementPlain()
        plcActionUp.posY = 308
        actionUp:SetPlacementPlain( plcActionUp )
        
        -- Отвечает за: Позицию нижней кнопки.
        local actionDown = rollTube:GetChildChecked( "ActionDown" )
        local plcActionDown = actionDown:GetPlacementPlain()
        plcActionDown.posY = 308 + plcActionDown.sizeY
        actionDown:SetPlacementPlain( plcActionDown )
        
        -- Отвечает за: Размер основной колбы совместно с BackLayer текстурой.
        local plcRollTube = rollTube:GetPlacementPlain()
        plcRollTube.sizeY = 342 + plcActionDown.sizeY
        rollTube:SetPlacementPlain( plcRollTube )
        
        -- Отвечает за: Контейнер (Основная колба + Горелка под колбой)
        local plcBar = bar:GetPlacementPlain()
        plcBar.sizeY = 440 + plcActionDown.sizeY
        bar:SetPlacementPlain( plcBar )
        
        -- Отвечает за: Цифра над горелкой
        local correctionCount = bar:GetChildChecked( "CorrectionCount" )
        local plcCorrectionCount = correctionCount:GetPlacementPlain()
        plcCorrectionCount.sizeY = 20 + 10
        correctionCount:SetPlacementPlain( plcCorrectionCount )
    end
    
    -- Отвечает за: Контейнер c 5ю колбами (Иконки над колбой + Основная колба + Горелка под колбой)
    local plcRolls = rolls:GetPlacementPlain()
    plcRolls.sizeY = 440 + 26
    plcRolls.highPosY = 15 - 26
    rolls:SetPlacementPlain( plcRolls )
end

function WidgetRollsBar:GetNativeWidget() --- ?Widget
    return nil
end

function WidgetRollsBar:GetWidgetName() --- string
    return "rollsBar"
end