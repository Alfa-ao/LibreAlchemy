-- AlchemyDebugService.lua

Class( "AlchemyDebugService", {
    _categories = {},
})

function AlchemyDebugService:Init( config )
    self._categories = {
        GENERAL  = config.DEBUG,           -- Общая логика
        REACTION = config.DEBUG_REACTION,  -- Дебаг реакции
    }
end

-- Включить/выключить конкретную категорию
function AlchemyDebugService:SetEnabled( category, isEnabled )
    if self._categories[category] ~= nil then
        self._categories[category] = isEnabled
    end
end

-- Проверка включена ли категория
function AlchemyDebugService:IsEnabled( category )
    return self._categories[category] == true
end

-- Базовый метод логирования.
function AlchemyDebugService:Log( category, ... )
    if not self:IsEnabled( category ) then return end
    
    local args = { ... }
    local message = ""
    for i, v in ipairs( args ) do
        if type( v ) == "function" then
            v = tostring( v() )
        else
            v = tostring( v )
        end
        message = message .. v .. ( i < #args and " " or "" )
    end
    
    common.LogInfo( "", message )
end

function AlchemyDebugService:LogGeneral( ... )  self:Log( "GENERAL", ... )  end
function AlchemyDebugService:LogReaction( ... ) self:Log( "REACTION", ... ) end
function AlchemyDebugService:LogSearch( ... )   self:Log( "SEARCH", ... )   end
function AlchemyDebugService:LogUI( ... )       self:Log( "UI", ... )       end