--------------------------------------------------------------------------------
-- Services/AlchemyLocaleService.lua
-- Сервис для работы с локализацией аддона.
-- Предоставляет методы для получения переведенных строк по ключам из
-- ресурсных файлов локализации (UIRelatedTexts).
--------------------------------------------------------------------------------

Class( "AlchemyLocaleService", {
	_group = nil, -- Текущая группа локализованных текстов (UIRelatedTextsGroup).
} )

--------------------------------------------------------------------------------

-- Инициализация сервиса локализации.
-- Загружает группу текстов для текущей локали клиента. Если локаль не найдена,
-- используется английская ("eng").
function AlchemyLocaleService:Init() --- void
	self._group = common.GetAddonRelatedTextGroup(
		common.GetLocalization(), true
	) or common.GetAddonRelatedTextGroup( "eng" )
end

--------------------------------------------------------------------------------

-- Получить локализованную строку по ключу.
-- Конвертирует внутреннее представление WString в обычную Lua-строку.
function AlchemyLocaleService:Get( key ) --- string
	if self._group and self._group:HasText( key ) then
		return userMods.FromWString( self._group:GetText( key ) )
	end
	
	-- Если ключ не найден, выбрасываем ошибку с указанием отсутствующего ключа
	error( string.format( "AlchemyLocaleService: Locale key '%s' not found in text group.", tostring( key ) ) )
end