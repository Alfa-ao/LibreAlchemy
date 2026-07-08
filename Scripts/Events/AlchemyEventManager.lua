--------------------------------------------------------------------------------
-- Events/AlchemyEventManager.lua
-- Централизованный менеджер событий.
-- Автоматизирует регистрацию и дерегистрацию обработчиков событий,
-- собирая их из классов, реализующих интерфейс EventClassInterface.
--------------------------------------------------------------------------------

Class( "AlchemyEventManager", {
    _handlers = {},          -- table - Массив зарегистрированных обработчиков (инстансов EventClassInterface).
    _registeredEvents = {},  -- table - Трекер зарегистрированных событий. Структура: { [eventName] = { callback1, callback2, ... } }.
})

--------------------------------------------------------------------------------
--- Инициализация и валидация зависимостей.
--- Принимает произвольное количество классов-обработчиков.
--- Проверяет, что каждый переданный объект реализует интерфейс EventClassInterface.
--- @param ... table EventClassInterface
--------------------------------------------------------------------------------
function AlchemyEventManager:Init( ... ) --- void
    local handlers = { ... }
    for id, handler in ipairs( handlers ) do
        -- Проверка на реализацию интерфейса
        if InstanceOf( handler, _G.EventClassInterface ) then
            self._handlers[id] = handler
        else
            -- Если интерфейс не реализован, выбрасываем ошибку
            local objectClass = GetParentClass( handler )
            local className = GetClassName( objectClass )
            
            error( string.format( 
                "Unsupported class '%s' does not have an interface 'EventClassInterface'", 
                className 
            ) )
        end
    end
end

--------------------------------------------------------------------------------
-- Массовая регистрация / дерегистрация событий
--------------------------------------------------------------------------------

-- Проходит по всем инициализированным обработчикам и регистрирует.
function AlchemyEventManager:RegisterAll() --- void
    for _, handler in ipairs( self._handlers ) do
        -- Получаем таблицу { [EVENT_NAME] = handlerMethod, ... }
        local eventMap = handler:GetEventMap() 
        
        for eventName, method in pairs( eventMap ) do
            -- Создаем замыкание, чтобы "запомнить" контекст (handler) 
            -- для возможности вызова метода с нужным self.
            local callback = function( ... )
                return method( handler, ... )
            end
            
            self:Register( eventName, callback )
        end
    end
end

--------------------------------------------------------------------------------

-- Отменяет регистрацию всех отслеживаемых событий и очищает трекер.
function AlchemyEventManager:UnRegisterAll() --- void
    for eventName, handlers in pairs( self._registeredEvents ) do
        for _, method in ipairs( handlers ) do
            common.UnRegisterEventHandler( method, eventName )
        end
    end
    -- Очистка
    self._registeredEvents = {}
end

--------------------------------------------------------------------------------
-- Работа с отдельными событиями
--------------------------------------------------------------------------------

-- Регистрирует один конкретный обработчик события и сохраняет его в трекер.
function AlchemyEventManager:Register( eventName, method ) --- void
    -- Инициализируем массив для события, если его еще нет
    if not self._registeredEvents[eventName] then
        self._registeredEvents[eventName] = {}
    end
    
    -- Сохраняем ссылку на callback для возможности дерегистрации
    table.insert( self._registeredEvents[eventName], method )
    
    -- Регистрация
    common.RegisterEventHandler( method, eventName )
end

--------------------------------------------------------------------------------

-- Отменяет регистрацию конкретного обработчика для указанного события.
function AlchemyEventManager:UnRegister( eventName, method ) --- void
    local handlers = self._registeredEvents[eventName]
    if not handlers then return end

    -- Ищем обработчик в массиве и удаляем его
    for i = #handlers, 1, -1 do
        if handlers[i] == method then
            table.remove( handlers, i )
            -- Дерегистрация
            common.UnRegisterEventHandler( method, eventName )
            break
        end
    end

    -- Очистка записи события из трекера, если для него не осталось обработчиков
    if #handlers == 0 then
        self._registeredEvents[eventName] = nil
    end
end

--------------------------------------------------------------------------------
-- Ручная диспетчеризация (эмуляция событий)
-- Принудительно вызывает все зарегистрированные обработчики для указанного события.
--------------------------------------------------------------------------------
function AlchemyEventManager:Dispatch( eventName, ... ) --- void
    local handlers = self._registeredEvents[eventName]
    if handlers then
        for _, method in ipairs( handlers ) do
            method( ... )
        end
    end
end