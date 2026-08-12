--------------------------------------------------------------------------------
-- Core/AlchemyInit.lua
-- Главный скрипт инициализации LibreAlchemyV2.
-- Создание экземпляров, их связывание (внедрение зависимостей) и запуск.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Методы обвертки для логирования.
--------------------------------------------------------------------------------
function AlchemyDebugService:LogGeneral( ... )
    self:Log( "GENERAL", ... )
end

function AlchemyDebugService:LogReaction( ... )
    self:Log( "REACTION", ... )
end

--------------------------------------------------------------------------------
-- Создание и настройка базовых объектов состояния и конфигурации.
--------------------------------------------------------------------------------
local config = AlchemyConfig()
local state  = AlchemyState()

-- При первом входе показывает HELLO сообщение.
state.messageType = config.MESSAGE_GREETINGS

-- Инициализация вспомогательных утилит.
local mathUtils = MathUtils()

--------------------------------------------------------------------------------
-- Создание сервисов.
--------------------------------------------------------------------------------
local services = {
    -- Сервис для отладки и логирования. Принимает настройки из конфига.
    debug = AlchemyDebugService(),

    -- Сервис локализации. Отвечает за получение текстов на нужном языке.
    locale = AlchemyLocaleService(),

    -- Сервис шаблонов. Отвечает за получение шаблонных HTML-блоков.
    template = AlchemyTemplateService(),

    -- Сервис работы с рецептами. Кэширует, фильтрует и подсчитывает рецепты.
    recipe = AlchemyRecipeService(),

    -- Сервис поиска возможных рецептов с учетом сдвигов барабанов.
    search = AlchemySearchService(),

    -- Сервис для управления текстовым контейнером.
    textContainer = AlchemyTextContainerService(),

    -- Drag & Drop менеджер.
    dnd = DnDManager(),
}

--------------------------------------------------------------------------------
-- Инициализация сервисов.
--------------------------------------------------------------------------------
services.debug:Init {
    GENERAL  = config.DEBUG,
    REACTION = config.DEBUG_REACTION,
}

services.recipe:Init( state )
services.locale:Init()
services.template:Init()

-- autoRegisterEvents = false отменяет автоматическую регистрацию событий.
-- Ручная регистрация через AlchemyDNDEvents / AlchemyPosEvents.
services.dnd:Init { autoRegisterEvents = false, defaultCursor = "drag" }

--------------------------------------------------------------------------------
-- Инициализация подсистемы поиска.
--------------------------------------------------------------------------------

-- Маппер сдвигов барабанов.
local drumShiftMapper = DrumShiftMapper()

-- Алгоритм поиска (Backtracking).
local searchAlgorithm = BacktrackingSearchAlgorithm()

-- Связывание компонентов подсистемы поиска.
drumShiftMapper:Init( state, services.recipe, mathUtils )

-- Передача оценщика рецептов (RecipeEvaluator) и утилиты.
searchAlgorithm:Init( RecipeEvaluator(), mathUtils )

-- Инициализация главного сервиса поиска.
services.search:Init(
    state,
    services.recipe,
    drumShiftMapper,
    searchAlgorithm
)

--------------------------------------------------------------------------------
-- Инициализация связанное с интерфейсом.
--------------------------------------------------------------------------------

-- Менеджер виджетов.
local widgetManager = AlchemyWidgetManager()

-- Форматировщик текста.
local textFormatter = AlchemyTextFormatter()

--------------------------------------------------------------------------------
-- Создание контекста зависимостей.
--------------------------------------------------------------------------------
local context = AlchemyContext()

context:Init {
    state = state,
    config = config,
    widgetManager = widgetManager,
    textFormatter = textFormatter,
    services = services,
}

--------------------------------------------------------------------------------
-- Инициализация менеджера виджетов.
--------------------------------------------------------------------------------
widgetManager:Init(
    {
        WidgetOuText(),
        WidgetDnD(),
        WidgetAlchemyV2(),
        WidgetPanel(),
    },
    context
)

--------------------------------------------------------------------------------
-- Инициализация форматировщика текста.
--------------------------------------------------------------------------------
textFormatter:Init( context )

--------------------------------------------------------------------------------
-- Централизованный менеджер событий.
--------------------------------------------------------------------------------
local eventManager = AlchemyEventManager()

eventManager:Init(
    {
        AlchemyEvents(),
        AlchemyAvatarEvents(),
        AlchemyPosEvents(),
        AlchemyDNDEvents(),
    },
    context
)

eventManager:RegisterAll()

--------------------------------------------------------------------------------
-- Инициализация и запуск.
--------------------------------------------------------------------------------
local bootstrap = AlchemyBootstrap()
bootstrap:Init( eventManager )
bootstrap:Run()