--------------------------------------------------------------------------------
-- Core/AlchemyInit.lua
-- Главный скрипт инициализации LibreAlchemyV2.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Для логирования.
--------------------------------------------------------------------------------
function AlchemyDebugService:LogGeneral( ... )
    self:Log( "GENERAL", ... )
end

function AlchemyDebugService:LogReaction( ... )
    self:Log( "REACTION", ... )
end

--------------------------------------------------------------------------------
-- Конфиг и состояние.
--------------------------------------------------------------------------------
local config = AlchemyConfig
local state  = AlchemyState()
state.messageType = config.MESSAGE_GREETINGS

local mathUtils = MathUtils()

--------------------------------------------------------------------------------
-- Сервисы.
--------------------------------------------------------------------------------
local services = {
    -- Дебаг.
    debug = AlchemyDebugService(),

    -- Сервис локализации. RUS, ENG.
    locale = AlchemyRelatedTextService(),

    -- Шаблоны <html> из Locales/template/UIRelatedTexts.
    template = AlchemyRelatedTextService(),

    -- Кэш 250 и более зельев.
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
services.locale:Init( common.GetLocalization() )
services.template:Init( "template" )

-- autoRegisterEvents = false отменяет автоматическую регистрацию событий.
-- Ручная регистрация через AlchemyDNDEvents / AlchemyPosEvents.
services.dnd:Init { autoRegisterEvents = false, defaultCursor = "drag" }

--------------------------------------------------------------------------------
-- По алхимке поиск рецептов.
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
-- Подготовка контекста.
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
-- Виджеты.
--------------------------------------------------------------------------------
widgetManager:Init(
    {
        WidgetOuText(),
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
-- События.
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