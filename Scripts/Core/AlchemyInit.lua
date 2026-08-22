--------------------------------------------------------------------------------
-- Core/AlchemyInit.lua
--------------------------------------------------------------------------------

-- Для логирования
local VAR_DEBUG_EXISTS = apitype( rawget( _G, "var_dump" ) ) == "function"

Global( "log", function( ... )
    if VAR_DEBUG_EXISTS then
        common.LogInfo( "common", var_dump( ... ) )
    else
        for _, value in ipairs { ... } do
            common.LogInfo( "common", tostring( value ) )
        end
    end
end )

function AlchemyDebugService:LogGeneral( ... )
    self:Log( "GENERAL", ... )
end

function AlchemyDebugService:LogReaction( ... )
    self:Log( "REACTION", ... )
end

--------------------------------------------------------------------------------
-- Cостояние и вспомогательные функции.
--------------------------------------------------------------------------------
local state  = AlchemyState()
state.messageType = CONFIG.MESSAGE_GREETINGS

local mathUtils = MathUtils()

--------------------------------------------------------------------------------
-- Сервисы.
--------------------------------------------------------------------------------
local debugService = AlchemyDebugService() -- Лог.
debugService:Init { GENERAL = CONFIG.DEBUG, REACTION = CONFIG.DEBUG_REACTION }

local localeService = AlchemyRelatedTextService() -- RUS, ENG.
localeService:Init( common.GetLocalization() )

local templateService = AlchemyRelatedTextService() -- Шаблоны <html> из Locales/template/UIRelatedTexts.
templateService:Init( "template" )

local recipeService = AlchemyRecipeService() -- Кэш 250 и более зельев.
recipeService:Init( state )

local dndManager = DnDManager()
dndManager:Init { defaultCursor = "drag" }

--------------------------------------------------------------------------------
-- По алхимке поиск рецептов.
--------------------------------------------------------------------------------
local drumShiftMapper = DrumShiftMapper()
drumShiftMapper:Init( state, recipeService, mathUtils )

local searchAlgorithm = BacktrackingSearchAlgorithm()
searchAlgorithm:Init( RecipeEvaluator(), mathUtils )

local searchService = AlchemySearchService()
searchService:Init( state, recipeService, drumShiftMapper, searchAlgorithm )

--------------------------------------------------------------------------------
-- Виджеты.
--------------------------------------------------------------------------------
local widgetAlchemyV2 = WidgetAlchemyV2()
widgetAlchemyV2:Init()

--------------------------------------------------------------------------------
-- Всё что связано с текстом, почти.
--------------------------------------------------------------------------------
local textContainerService = AlchemyTextContainerService()
textContainerService:Init()

local textFormatter = AlchemyTextFormatter()
textFormatter:Init( widgetAlchemyV2, templateService )

--------------------------------------------------------------------------------
-- Логика в событиях связано с алхимкой.
--------------------------------------------------------------------------------
local alchemyEvents = AlchemyEvents()
alchemyEvents:Init {
    state         = state,
    textContainer = textContainerService,
    formatter     = textFormatter,
    search        = searchService,
    recipe        = recipeService,
    debug         = debugService,
    locale        = localeService,
}

local avatarEvents = AlchemyAvatarEvents()
avatarEvents:Init {
    state         = state,
    AlchemyV2     = widgetAlchemyV2,
    textContainer = textContainerService,
    debug         = debugService,
    locale        = localeService,
    dnd           = dndManager,
}

--------------------------------------------------------------------------------
-- Регистрация событий.
--------------------------------------------------------------------------------
-- Алхимия
common.RegisterEventHandler( function() alchemyEvents:OnStarted() end, "EVENT_ALCHEMY_STARTED" )                        -- Окно алхимки открывается. Инициализируется HELLO сообщение и кэш рецептов.
common.RegisterEventHandler( function( params ) alchemyEvents:OnCanceled( params ) end, "EVENT_ALCHEMY_CANCELED" )      -- Окно алхимки закрывается / вышли из варки в меню.
common.RegisterEventHandler( function( params ) alchemyEvents:OnItemPlaced( params ) end, "EVENT_ALCHEMY_ITEM_PLACED" ) -- При каждом изменении слота для компонентов уведомляет, что в такой-то слот был вставлен/вынут компонент.
common.RegisterEventHandler( function() alchemyEvents:OnReactionFinished() end, "EVENT_ALCHEMY_REACTION_FINISHED" )     -- Уведомляет о начале варки зелья. Хоть и название события говорит о другом...
common.RegisterEventHandler( function() alchemyEvents:OnRecipesChanged() end, "EVENT_ALCHEMY_RECIPES_CHANGED" )         -- Уведомляет об необходимости обновить список рецептов.

-- Аватар
common.RegisterEventHandler( function() avatarEvents:OnAvatarCreated() end, "EVENT_AVATAR_CREATED" )                    -- Инициализация логики. Когда игрок уже в игре, ТОЛЬКО ТОГДА необходимо применинить следующую логику.
common.RegisterEventHandler( function( params ) avatarEvents:OnItemTaken( params ) end, "EVENT_AVATAR_ITEM_TAKEN" )     -- Всё что попало в сумку игрока от крафта алхимки.

--------------------------------------------------------------------------------
-- Повторно событие EVENT_AVATAR_CREATED не прийдет, т.к. аватар уже находиться в игре.
-- Если аддон по каким-то причинам load/reload.
--------------------------------------------------------------------------------
if avatar.IsExist() then
    avatarEvents:OnAvatarCreated()
end