--------------------------------------------------------------------------------
-- Core/AlchemyInit.lua
-- Главный скрипт инициализации LibreAlchemyV2.
-- Здесь происходит создание экземпляров всех классов, их связывание (внедрение зависимостей)
-- и первый запуск. Порядок инициализации строго важен, так как классы зависят друг от друга.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Методы обвертки для логирования.
--------------------------------------------------------------------------------

function AlchemyDebugService:LogGeneral( ... )  self:Log( "GENERAL", ... )  end
function AlchemyDebugService:LogReaction( ... ) self:Log( "REACTION", ... ) end

--------------------------------------------------------------------------------

-- Создание и настройка базовых объектов состояния и конфигурации.
-- Конфигурация хранит константы и настройки, состояние - изменяемые данные во время работы.
local config = AlchemyConfig()
local state  = AlchemyState()
-- Устанавливает начальное состояние UI: при первом входе показывает приветственное сообщение
state.messageType = config.MESSAGE_GREETINGS

-- Инициализация вспомогательных утилит.
local mathUtils = MathUtils()

--------------------------------------------------------------------------------
-- Создание и регистрация основных сервисов.
--------------------------------------------------------------------------------
local services = { 
    -- Сервис для отладки и логирования. Принимает настройки из конфига.
    debug = AlchemyDebugService(),
    -- Сервис локализации. Отвечает за получение текстов на нужном языке (ENG, RUS).
    locale = AlchemyLocaleService(),
    -- Сервис шаблонов. Отвечает за получение шаблоных блоков HTML.
    template = AlchemyTemplateService(),
    -- Сервис работы с рецептами. Кэширует, фильтрует и подсчитывает возможные рецепты.
    recipe = AlchemyRecipeService(),
    -- Сервис поиска возможных рецептов с учетом сдвигов барабанов (коррекций).
    search = AlchemySearchService(),
    -- Сервис для управления текстовым контейнером.
    textContainer = AlchemyTextContainerService(),
    -- Drag&Drop менеджер.
    dnd = DnDManager(),
}

-- Инициализация сервисов.
services.debug:Init( {
    GENERAL  = config.DEBUG,           -- Общая логика аддона.
    REACTION = config.DEBUG_REACTION,  -- Логирование реакций.
} )
services.recipe:Init( state )
services.locale:Init()
services.template:Init()
services.dnd:Init( { autoRegisterEvents = false } ) -- autoRegisterEvents = false отменяет автоматическую регистрацию, в пользу ручного.

--------------------------------------------------------------------------------
-- Инициализация подсистемы поиска.
-- Включает в себя маппер сдвигов и конкретный алгоритм поиска.
--------------------------------------------------------------------------------

-- Маппер сдвигов барабанов: определяет, какие компоненты доступны при разных сдвигах.
local drumShiftMapper = DrumShiftMapper()
-- Алгоритм поиска (Backtracking).
local searchAlgorithm = BacktrackingSearchAlgorithm()

-- Связывание компонентов подсистемы поиска.
drumShiftMapper:Init( state, services.recipe, mathUtils )
-- Оценщик рецептов (RecipeEvaluator) и утилиты передаются в алгоритм.
searchAlgorithm:Init( RecipeEvaluator(), mathUtils )
-- Инициализация главного сервиса поиска со всеми его зависимостями.
services.search:Init( state, services.recipe, drumShiftMapper, searchAlgorithm )

--------------------------------------------------------------------------------
-- Инициализация пользовательского интерфейса (UI).
--------------------------------------------------------------------------------

-- Менеджер виджетов управляет отображением, скрытием и получением нативных виджетов.
local widgetManager = AlchemyWidgetManager()
-- Передача обертки над нативными виджетами: текстовый контейнер, Drag&Drop зона, барабаны алхимии.
widgetManager:Init( { WidgetOuText(), WidgetDnD(), WidgetAlchemyV2(), WidgetPanel() }, services )

-- Форматировщик текста: подготавливает данные для вывода в UI, форматирует строки рецептов.
local textFormatter = AlchemyTextFormatter()
textFormatter:Init( widgetManager, services )

--------------------------------------------------------------------------------
-- Централизованный менеджер событий.
--------------------------------------------------------------------------------
local eventManager = AlchemyEventManager()
eventManager:Init( 
    { AlchemyEvents(), AlchemyAvatarEvents(), AlchemyPosEvents(), AlchemyDNDEvents() },
    { state, config, widgetManager, textFormatter, services }
)
eventManager:RegisterAll()

--------------------------------------------------------------------------------
-- Инициализация и запуск аддона.
--------------------------------------------------------------------------------
local bootstrap = AlchemyBootstrap()
bootstrap:Init( eventManager )
bootstrap:Run()