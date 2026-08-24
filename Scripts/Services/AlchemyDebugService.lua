--------------------------------------------------------------------------------
-- Services/AlchemyDebugService.lua
-- Сервис для управления отладочным логированием аддона.
--------------------------------------------------------------------------------

Class( "AlchemyDebugService", {
	_categories = nil, -- Таблица состояния категорий логирования (category - имя категории, значение - boolean).
} )

--------------------------------------------------------------------------------
--- Инициализация сервиса отладки.
--- @param categories table
--------------------------------------------------------------------------------
function AlchemyDebugService:Init( categories )
	self._categories = type( categories ) == "table" and categories or {}
end

--------------------------------------------------------------------------------
--- Включить или выключить конкретную категорию логирования.
--- @param category string имя категории
--- @param isEnabled boolean 
--------------------------------------------------------------------------------
function AlchemyDebugService:SetEnabled( category, isEnabled )
	if self._categories[category] ~= nil then
		self._categories[category] = isEnabled
	end
end

--------------------------------------------------------------------------------
--- Проверить, включена ли указанная категория логирования.
--- @param category string имя категории
--- @return boolean
--------------------------------------------------------------------------------
function AlchemyDebugService:IsEnabled( category )
	return self._categories[category] == true
end

--------------------------------------------------------------------------------
--- Формирует строку сообщения и выводит её в лог.
--- @param category string категория логирования
--- @param ... any
--------------------------------------------------------------------------------
function AlchemyDebugService:Log( category, ... )
	if not self:IsEnabled( category ) then
		return
	end
	
	local args = { ... }
	
	for i, v in ipairs( args ) do
		if type( v ) == "function" then
			-- Если функция, вызываем её
			args[i] = v()
		elseif apitype( v ) == "WString" then
			-- Если WString, конвертируем в строку
			args[i] = string.format( "WString( %s )", userMods.FromWString( v ) )
		end
		-- :ToWString()
	end
	
	log( table.unpack( args ) )
end