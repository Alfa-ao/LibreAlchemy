-- AlchemyConfig.lua
-- Настройки по умолчанию.

Class( "AlchemyConfig", {
    MAX_DISPLAY_RESULTS = 5,     -- Максимальное кол-во ТОП-N возможных рецептов
    -- (DEPRECATED) DEFAULT_DRUMS = 2,           -- (Re: UIAddon) Кол-во слотов доступных в ступке.
    DEFAULT_MAX_CORRECTIONS = 6, -- Максимальная коррекция в колбе (в меню варки).

    -- messageType:
    MESSAGE_GREETINGS = 1,       -- "Приветствую!"
    MESSAGE_WELCOME_BACK = 2,    -- "С возвращением!"
    MESSAGE_WARNING = 3,         -- Предупреждение (нет LibDnD)
    MESSAGE_NORMAL = 0,          -- Остальное для алхимки

    -- Отладка
    DEBUG = false,
    DEBUG_REACTION = false,
})