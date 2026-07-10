--------------------------------------------------------------------------------
-- UI/Widgets/WidgetAlchemyV2.lua
-- Обертка для кастомизации стандартного интерфейса окна алхимии.
-- Изменяет размеры и позиции стандартных элементов (колб, кнопок, горелок).
--------------------------------------------------------------------------------

Class( "WidgetAlchemyV2", WidgetClassInterface() )

--------------------------------------------------------------------------------
--- Инициализация виджета
--- @param widgetManager table - экземпляр класса AlchemyWidgetManager
--------------------------------------------------------------------------------
function WidgetAlchemyV2:Init( widgetManager ) --- void
    self._widgetManager = widgetManager
    self._widget        = common.GetAddonMainForm( self:GetWidgetName() )
end

--------------------------------------------------------------------------------
-- Новый стиль окна с барабанами для Алхимии
--------------------------------------------------------------------------------
function WidgetAlchemyV2:InitCustomLayout() --- void
	-- AlchemyV2.MainFrame.Alchemy.Game.View.Rolls
    local rolls = self:GetNativeWidget():
        GetChildChecked( "MainFrame" ):
        GetChildChecked( "Alchemy" ):
        GetChildChecked( "Game" ):
        GetChildChecked( "View" ):
        GetChildChecked( "Rolls" )
    
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

--------------------------------------------------------------------------------
--- @return string -- Получить имя рецепта, выбранного в AlchemyV2 (в меню варки).
--------------------------------------------------------------------------------
function WidgetAlchemyV2:GetCurrentRecipeName()
    local nameWidget = self:GetNativeWidget():
        GetChildChecked( "MainFrame" ):
        GetChildChecked( "Alchemy" ):
        GetChildChecked( "Game" ):
        GetChildChecked( "View" ):
        GetChildChecked( "Recipe" ):
        GetChildChecked( "Name" )

    return nameWidget and userMods.FromWString( nameWidget:GetWString() ) or ""
end

--------------------------------------------------------------------------------
-- Реализация методов интерфейса WidgetClassInterface.
--------------------------------------------------------------------------------
--- @return userdata | table | nil
function WidgetAlchemyV2:GetNativeWidget()
    return self._widget
end

--- @return string
function WidgetAlchemyV2:GetWidgetName()
    return "AlchemyV2"
end