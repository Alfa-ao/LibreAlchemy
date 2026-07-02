--------------------------------------------------------------------------------
-- Services/AlchemyDebugService.lua
-- Сервис для управления отладочным логированием аддона.
-- Позволяет включать/выключать логирование по категориям и предоставляет
-- удобные методы для вывода сообщений в игровой лог.
--------------------------------------------------------------------------------

Class( "AlchemyDebugService", {
	_categories = {}, -- Таблица состояния категорий логирования (ключ - имя категории, значение - boolean).
} )

--------------------------------------------------------------------------------
-- Инициализация сервиса отладки.
--------------------------------------------------------------------------------

function AlchemyDebugService:Init( config ) --- void
	self._categories = {
		GENERAL  = config.DEBUG,           -- Общая логика аддона.
		REACTION = config.DEBUG_REACTION,  -- Логирование событий и реакций.
	}
end

--------------------------------------------------------------------------------

-- Включить или выключить конкретную категорию логирования.
function AlchemyDebugService:SetEnabled( category, isEnabled ) --- void
	if self._categories[category] ~= nil then
		self._categories[category] = isEnabled
	end
end

--------------------------------------------------------------------------------

-- Проверить, включена ли указанная категория логирования.
function AlchemyDebugService:IsEnabled( category ) --- boolean
	return self._categories[category] == true
end

--------------------------------------------------------------------------------

-- Формирует строку сообщения и выводит её в лог.
-- Если в аргументах передана функция, она будет вызвана для получения значения.
function AlchemyDebugService:Log( category, ... ) --- void
	if not self:IsEnabled( category ) then
		return
	end
	
	local args = { ... }
	local message = ""
	
	-- Формируем итоговую строку сообщения
	for i, v in ipairs( args ) do
		if type( v ) == "function" then
			-- Если передана функция, вызываем её
			v = tostring( v() )
		else
			v = tostring( v )
		end
		-- Добавляем пробел между аргументами, если это не последний элемент
		message = message .. v .. ( i < #args and " " or "" )
	end
	
	common.LogInfo( "", message )
end

--------------------------------------------------------------------------------
-- Вспомогательные методы для логирования в предустановленные категории.
--------------------------------------------------------------------------------

function AlchemyDebugService:LogGeneral( ... )  self:Log( "GENERAL", ... )  end
function AlchemyDebugService:LogReaction( ... ) self:Log( "REACTION", ... ) end