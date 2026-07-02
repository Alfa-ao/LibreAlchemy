--------------------------------------------------------------------------------
-- Core/AlchemyBootstrap.lua
-- Класс-бутстрап (загрузчик) аддона.
-- Отвечает за первичный запуск аддона.
--------------------------------------------------------------------------------

--- Класс для начального запуска и связывания компонентов аддона.
Class( "AlchemyBootstrap", {
    _eventManager = nil, -- Ссылка на централизованный менеджер событий
} )

-- Инициализация бутстрапа.
-- Сохраняет ссылку на менеджер событий для дальнейшего использования.
-- @param eventManager table - экземпляр класса AlchemyEventManager
function AlchemyBootstrap:Init( eventManager ) --- void
    self._eventManager = eventManager
end

-- Запуск начальной логики аддона.
-- Проверяет, создан ли уже персонаж (аватар) на момент запуска аддона.
function AlchemyBootstrap:Run() --- void
    if avatar.IsExist() then
        self._eventManager:Dispatch( "EVENT_AVATAR_CREATED", { id = avatar.GetId() } )
    end
end