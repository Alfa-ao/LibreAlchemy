-- AlchemyEventManager.lua
-- Централизованный менеджер событий.

Class( "AlchemyEventManager", {
    _handlers = {},
    _registeredEvents = {}, -- { eventName = { callback1, callback2, ... } }
})

function AlchemyEventManager:Init( ... )
    self._handlers = { ... }
    self._registeredEvents = {}
end

function AlchemyEventManager:RegisterAll()
    for _, handler in ipairs( self._handlers ) do
        local eventMap = handler:GetEventMap() 
        
        for eventName, method in pairs( eventMap ) do
            -- Создаем замыкание, чтобы "запомнить" контекст (handler) для вызова метода
            local callback = function( ... )
                return method( handler, ... )
            end
            
            self:Register( eventName, callback )
        end
    end
end

-- Регистрация одного события
function AlchemyEventManager:Register( eventName, method )
    if not self._registeredEvents[eventName] then
        self._registeredEvents[eventName] = {}
    end
    
    table.insert( self._registeredEvents[eventName], method )
    
    common.RegisterEventHandler( method, eventName )
end

-- Отмена регистрации всех событий
function AlchemyEventManager:UnRegisterAll()
    for eventName, handlers in pairs( self._registeredEvents ) do
        for _, method in ipairs( handlers ) do
            common.UnRegisterEventHandler( method, eventName )
        end
    end
    self._registeredEvents = {}
end

-- Отмена регистрации конкретного обработчика для события
function AlchemyEventManager:UnRegister( eventName, method )
    local handlers = self._registeredEvents[eventName]
    if not handlers then return end

    -- Ищем обработчик в массиве и удаляем его
    for i = #handlers, 1, -1 do
        if handlers[i] == method then
            table.remove( handlers, i )
            common.UnRegisterEventHandler( method, eventName )
            break
        end
    end

    -- Очистка таблицы события, если обработчиков не осталось
    if #handlers == 0 then
        self._registeredEvents[eventName] = nil
    end
end

function AlchemyEventManager:Dispatch( eventName, ... )
    local handlers = self._registeredEvents[eventName]
    if handlers then
        for _, method in ipairs( handlers ) do
            method( ... )
        end
    end
end