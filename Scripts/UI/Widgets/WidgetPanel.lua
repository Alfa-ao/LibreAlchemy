--------------------------------------------------------------------------------
-- UI/Widgets/WidgetPanel.lua
-- Обертка над нативной панелью (Panel).
-- Отвечает за фоновую текстуру, глобальное позиционирование, 
-- динамическое изменение размеров и интеграцию с Drag & Drop.
--------------------------------------------------------------------------------

Class( "WidgetPanel", WidgetClassInterface() )

--------------------------------------------------------------------------------
-- Инициализация виджета.
--------------------------------------------------------------------------------
function WidgetPanel:Init( widgetManager ) --- void
    self._widgetManager = widgetManager
    self._widget = widgetManager:GetMainForm():GetChildChecked( "Panel" )

    -- Получаем параметры виртуального экрана для первичного позиционирования
    local pco = common.GetPosConverterParams()
    local plc = self._widget:GetPlacementPlain()

    -- Центрируем панель по горизонтали (с учетом отступов)
    plc.posX = pco.fullVirtualSizeX / 2 - 360 - 15
    -- Инвертируем координату Y для корректного отображения относительно верха экрана
    -- Подробности: https://github.com/Alfa-ao/LibreAlchemy/issues/1
    plc.posY = pco.fullVirtualSizeY - plc.posY

    self._widget:SetPlacementPlain( plc )
end

--------------------------------------------------------------------------------
-- Реализация методов интерфейса WidgetClassInterface.
--------------------------------------------------------------------------------
function WidgetPanel:GetPriorityClass() --- int
    -- Инициализируем раньше OuText и DnD, чтобы они могли безопасно получить ссылку на Panel
    return 20 
end

function WidgetPanel:GetNativeWidget() --- ?Widget
    return self._widget
end

function WidgetPanel:GetWidgetName() --- string
    return "panel"
end

--------------------------------------------------------------------------------
-- Динамически подстраивает размер Panel под переданную высоту текста + отступы.
-- Вызывается сервисом после обновления текста.
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