--------------------------------------------------------------------------------
-- Services/AlchemyDebugService.lua
-- Сервис для управления отладочным логированием аддона.
--------------------------------------------------------------------------------

Class( "AlchemyDebugService", {
	_categories = {}, -- Таблица состояния категорий логирования (ключ - имя категории, значение - boolean).
} )

--------------------------------------------------------------------------------
--- Инициализация сервиса отладки.
--- @param config table AlchemyConfig
--------------------------------------------------------------------------------
function AlchemyDebugService:Init( config ) --- void
	-- (ВНИМАНИЕ) В будующем переместить таблицу и убрать отсюда вспомогательные методы (расширяемость)
	self._categories = {
		GENERAL  = config.DEBUG,           -- Общая логика аддона.
		REACTION = config.DEBUG_REACTION,  -- Логирование событий и реакций.
	}
end

--------------------------------------------------------------------------------
--- Включить или выключить конкретную категорию логирования.
--- @param category string имя категории
--- @param isEnabled boolean 
--------------------------------------------------------------------------------
function AlchemyDebugService:SetEnabled( category, isEnabled ) --- void
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
--- Если в аргументах передана функция, она будет вызвана для получения значения.
--- @param category string категория логирования
--- @param ... any
--------------------------------------------------------------------------------
function AlchemyDebugService:Log( category, ... ) --- void
	if not self:IsEnabled( category ) then
		return
	end
	
	local args = { ... }
	
	-- Логируем
	for i, v in ipairs( args ) do
		if type( v ) == "function" then
			-- Если передана функция, вызываем её
			args[i] = v()
		end
	end
	
	log( table.unpack( args ) )
end

--------------------------------------------------------------------------------
-- Вспомогательные методы для логирования в предустановленные категории.
--------------------------------------------------------------------------------

function AlchemyDebugService:LogGeneral( ... )  self:Log( "GENERAL", ... )  end
function AlchemyDebugService:LogReaction( ... ) self:Log( "REACTION", ... ) end