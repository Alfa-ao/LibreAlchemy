--------------------------------------------------------------------------------
-- Enum/src/EnumFactory.lua
--------------------------------------------------------------------------------

--- Фабрика для создания перечислений (Enum).
--- @class EnumFactory
Global( "EnumFactory", {} )

--------------------------------------------------------------------------------
--- Создает перечисление на основе таблицы определений.
--- Поддерживает обратный поиск (значение -> ключ).
--- Результирующая таблица доступна только для чтения.
--- @param def table Определения (ключ -> значение).
--- @return table -- Перечисление.
--- @usage
--- EnumTakeItem = EnumFactory:create({
---     CRAFT = "ENUM_TakeItemActionType_Craft",
--- })
--------------------------------------------------------------------------------
function EnumFactory:create( def )
    local enum = {}
    
    for k, v in pairs( def ) do
        enum[k] = v
        enum[v] = k 
    end
    
    return setmetatable( enum, {
        __newindex = function() error( "Enum is read-only" ) end,
        __index = function( _, k ) error( "Invalid enum key: " .. tostring( k ) ) end,
    } )
end