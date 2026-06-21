--------------------------------------------------------------------------------
-- GLOBALS
--------------------------------------------------------------------------------

local LibreAlchemyClass = {}
LibreAlchemyClass.__index = LibreAlchemyClass

function LibreAlchemyClass:new()
    local instance = setmetatable( {}, self )

    -- messageType:
    -- 3: для предупреждений.
    -- 2: сообщение "С возвращением".
    -- 1: сообщение "Приветствую".
    -- 0: Остальные .
    instance.messageType = 1 -- (ПЕРЕДЕЛАТЬ=self:свойство)
    
    -- Забрали зелье после варки.
    instance.reactionSuccess = false 
    
    -- Состояние рабочей атмосферы.
    instance.lReci = nil       -- (ПЕРЕДЕЛАТЬ=название,self:свойство) Кэш списка всех доступных рецептов алхимии (таблица).
    instance.lFilt = nil       -- (ПЕРЕДЕЛАТЬ=название,self:свойство) Отфильтрованный список рецептов, подходящих под текущие компоненты в барабанах.
    instance.lCodr = nil       -- (ПЕРЕДЕЛАТЬ=название,self:свойство) Карта сдвигов: хранит компоненты в барабанах с учетом возможных сдвигов (индекс [барабан][сдвиг] = имя компонента).
    instance.lFound = nil      -- (ПЕРЕДЕЛАТЬ=название,self:свойство) Таблица найденных вариантов (рецепт + сдвиги барабанов).
    instance.nDrums = 2        -- (ПЕРЕДЕЛАТЬ=название,self:свойство) Стандартное/минимальное количество барабанов в алхимии.
    instance.nSinshi = 6       -- (ПЕРЕДЕЛАТЬ=название,self:свойство) Максимально допустимое количество коррекций (сдвигов) в барабане.
    instance.maxDisplay = 5    -- (ПЕРЕДЕЛАТЬ=self:свойство) Максимальное количество рецептов в Подсказке (топ-N результатов).

    instance.place = { -- (ПЕРЕДЕЛАТЬ=self:свойство)
        -- placed:
        -- nil: исходное состояние. 
        -- true: предметы вставлены.
        -- false: предметы убраны
        placed = nil, 
        readyNotFoundMessage = false,
        
		-- (ПЕРЕДЕЛАТЬ)
        -- В связи с тем, что имеем специфическую/(вынос мозга) работу с предоставленными API функциями,
        -- делаем счётчик в событии "EVENT_ALCHEMY_ITEM_PLACED" для посчёта вставленных компонентов.
        count = 0,
    }
    
    instance.widgets = {}            -- (ПЕРЕДЕЛАТЬ=self:свойство) Виджеты.
    instance.events = {}             -- (ПЕРЕДЕЛАТЬ=self:свойство) События.
    instance.fn = {}				 -- (ПЕРЕДЕЛАТЬ) Функции. Alchemy = { ... }
    instance.locales = {}			 -- (ПЕРЕДЕЛАТЬ=self:свойство) Локализация аддона eng, rus.
    instance.debug = true			 -- (ПЕРЕДЕЛАТЬ=self:свойство) Дебаг Аддона, особенно на событиях.
    instance.debugReaction = false   -- (DEPRECATED) Дебаг списка подсказки в окне (EVENT_ALCHEMY_REACTION_FINISHED)

    return instance
end

-- new class
Global( "LibreAlchemy", LibreAlchemyClass:new() )

if rawget( _G, "Facade" ) then
	Global( "log", _G.Facade.customAO.log )
end