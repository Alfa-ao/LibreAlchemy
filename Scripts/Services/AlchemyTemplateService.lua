--------------------------------------------------------------------------------
-- Services/AlchemyTemplateService.lua
-- Сервис для работы с локализованными шаблонами аддона.
--------------------------------------------------------------------------------

Class( "AlchemyTemplateService", {
	_group = nil,
} )

--------------------------------------------------------------------------------
-- Инициализация сервиса шаблонов.
--------------------------------------------------------------------------------
function AlchemyTemplateService:Init() --- void
	self._group = common.GetAddonRelatedTextGroup( "template" )
end

--------------------------------------------------------------------------------
--- Получить WString данные по ключу.
--- @param key string
--- @return userdata -- ссылка на текстовый ресурс
--------------------------------------------------------------------------------
function AlchemyTemplateService:Get( key )
	if self._group and self._group:HasText( key ) then
		return self._group:GetText( key )
	end
	
	-- Если ключ не найден, выбрасывает ошибку с указанием отсутствующего ключа
	error( string.format( "AlchemyTemplateService: Template key '%s' not found in text group.", tostring( key ) ) )
end