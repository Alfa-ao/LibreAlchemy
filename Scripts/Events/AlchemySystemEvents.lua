--------------------------------------------------------------------------------
-- Events/AlchemySystemEvents.lua
-- Класс, отвечающий за обработку системных событий (EVENT_SECOND_TIMER).
-- Используется для фоновых проверок состояния UI и отложенного вывода сообщений.
--------------------------------------------------------------------------------

Class( "AlchemySystemEvents", EventClassInterface() )

--------------------------------------------------------------------------------
--- Инициализация
--- @param state table AlchemyState
--- @param config table AlchemyConfig
--- @param textFmt table AlchemyTextFormatter
--- @param services table Services
--------------------------------------------------------------------------------
function AlchemySystemEvents:Init( state, config, textFmt, services ) --- void
    self._state    = state      -- AlchemyState - глобальное состояние аддона.
    self._config   = config     -- AlchemyConfig - конфигурация аддона.
    self._text     = textFmt    -- AlchemyTextFormatter - форматировщик текста.
    self._services = services   -- table - набор сервисов (debug, locale и т.д.).
end

--------------------------------------------------------------------------------
--- Маппинг событий
--- Возвращает таблицу соответствия имен событий методам-обработчикам.
--- Используется AlchemyEventManager для автоматической регистрации.
--- @return table
--------------------------------------------------------------------------------
function AlchemySystemEvents:GetEventMap()
    return {
        EVENT_SECOND_TIMER = self.OnSecondTimer, -- Срабатывает каждую секунду (игровой таймер).
    }
end

--------------------------------------------------------------------------------
-- Обработчики событий
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Обработчик события EVENT_SECOND_TIMER.
-- Выполняется каждую секунду. Используется для отложенного вывода сообщения
-- "Тут нет рецептов", чтобы дать нативному UI время обновить состояние слотов.
--------------------------------------------------------------------------------
function AlchemySystemEvents:OnSecondTimer() --- void
    -- Проверяем условия:
        -- Было зафиксировано открытие окна Алхимии событием.
        -- Из слота был извлечен предмет (placed == false, а не nil).
        -- Окно алхимии в игре все еще открыто (avatar.GetAlchemyInfo().active).
    if 
        self._state.active 
        and 
        self._state.place.placed == false 
        and 
        avatar.GetAlchemyInfo().active 
    then
        -- Если флаг готов к выводу сообщения (прошла 1 секунда после извлечения)
        if self._state.place.readyNotFoundMessage then
            -- Выводим сообщение об отсутствии подходящих рецептов
            self._text:SetText( self._services.locale:Get( "NOT_FOUND_RECIPLES" ) )
            
            -- Сбрасываем флаги, чтобы сообщение не выводилось повторно каждый тик таймера
            self._state.place.placed = nil
            self._state.place.readyNotFoundMessage = false
        else
            -- Иначе просто помечаем, что на следующем тике (через 1 сек) можно показать сообщение
            self._state.place.readyNotFoundMessage = true
        end
    end

    -- Если окно алхимии активно, сбрасываем тип сообщения на стандартный (MESSAGE_NORMAL).
    -- Это необходимо, чтобы после первого приветствия или сообщения "С возвращением!" 
    -- UI перешел в нормальный режим отображения количества рецептов при взаимодействии с барабанами.
    if self._state.active then
        self._state.messageType = self._config.MESSAGE_NORMAL
    end
end