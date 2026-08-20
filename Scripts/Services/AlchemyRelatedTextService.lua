--------------------------------------------------------------------------------
-- Services/AlchemyRelatedTextService.lua
-- Сервис для работы с текстовыми ресурсами.
--------------------------------------------------------------------------------

Class( "AlchemyRelatedTextService", {
    _group = nil,   -- RelatedTexts - Загруженная группа текстовых ресурсов
    _cache = nil,   -- table - Кэш полученных текстов { [key] = textResource }
} )

--------------------------------------------------------------------------------
--- Инициализация сервиса.
--- @param sysGroup string Имя группы.
--------------------------------------------------------------------------------
function AlchemyRelatedTextService:Init( sysGroup )
    self._group = common.GetAddonRelatedTextGroup( sysGroup, true )
    
    if not self._group then
        error( string.format( "AlchemyRelatedTextService:Init - Failed to load text group '%s', result is nil.", tostring( sysGroup ) ) )
    end
    
    self._cache = {}
end

--------------------------------------------------------------------------------
--- Получить текстовый ресурс по ключу.
--- @param key string Ключ текста.
--- @return WString
--------------------------------------------------------------------------------
function AlchemyRelatedTextService:Get( key )
    if self._cache[ key ] then
        return self._cache[ key ]
    end
    
    if self._group and self._group:HasText( key ) then
        local textResource = self._group:GetText( key )
        self._cache[ key ] = textResource
        return textResource
    end
    
    error( string.format( "AlchemyRelatedTextService:Get - Text key '%s' not found in the loaded group.", tostring( key ) ) )
end