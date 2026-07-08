--------------------------------------------------------------------------------
-- UI/Widgets/WidgetPanel.lua
-- Обертка над нативной панелью (Panel).
-- Отвечает за фоновую текстуру, глобальное позиционирование, 
-- динамическое изменение размеров и подключение для Drag & Drop.
--------------------------------------------------------------------------------

Class( "WidgetPanel", WidgetClassInterface() )

--------------------------------------------------------------------------------
--- Инициализация виджета.
--- @param widgetManager table - экземпляр класса AlchemyWidgetManager
--------------------------------------------------------------------------------
function WidgetPanel:Init( widgetManager ) --- void
    self._widgetManager = widgetManager
    self._widget = widgetManager:GetMainForm():GetChildChecked( "Panel" )

    -- Получаем параметры виртуального экрана
    local pco = common.GetPosConverterParams()
    local plc = self._widget:GetPlacementPlain()

    -- Центрируем панель по горизонтали
    plc.posX = pco.fullVirtualSizeX / 2 - 360 - 15
    -- Инвертируем координату Y для корректного отображения относительно верха экрана
    -- Подробности: https://github.com/Alfa-ao/LibreAlchemy/issues/1
    plc.posY = pco.fullVirtualSizeY - plc.posY

    self._widget:SetPlacementPlain( plc )
end

--------------------------------------------------------------------------------
-- Реализация методов интерфейса WidgetClassInterface.
--------------------------------------------------------------------------------
--- @return number
function WidgetPanel:GetPriorityClass()
    -- Инициализируем раньше OuText и DnD
    return 20
end

--- @return userdata | table | nil
function WidgetPanel:GetNativeWidget()
    return self._widget
end

--- @return string
function WidgetPanel:GetWidgetName()
    return "panel"
end

--------------------------------------------------------------------------------
--- Динамически подстраивает размер Panel под переданную высоту текста + отступы.
--- Вызывается сервисом (AlchemyTextContainerService) после обновления текста.
--- @param textHeight number
--------------------------------------------------------------------------------
function WidgetPanel:UpdateSize( textHeight ) --- void
    local padding = 15
    -- Получаем текущие параметры вложенного текстового контейнера
    local ouText = self._widget:GetChildChecked( "ouText" )
    local ouTextPlc = ouText:GetPlacementPlain()

    -- Вычисляем итоговые размеры панели
    -- Ширина: отступ слева (posX) + фиксированная ширина текста (sizeX) + отступ справа
    local targetSizeX = ouTextPlc.posX + ouTextPlc.sizeX + padding
    -- Высота: отступ сверху (posY) + (ТОЧНАЯ fontsize="15") высота текста + отступ снизу
    local targetSizeY = ouTextPlc.posY + textHeight + padding

    -- Применяем новый размер к Panel
    local panelPlc = self._widget:GetPlacementPlain()
    panelPlc.sizeX = targetSizeX
    panelPlc.sizeY = targetSizeY
    self._widget:SetPlacementPlain( panelPlc )
end