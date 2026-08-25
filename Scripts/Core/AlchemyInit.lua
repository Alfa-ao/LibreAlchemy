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
-- Cостояние.
--------------------------------------------------------------------------------
local state  = AlchemyState { messageType = CONFIG.MESSAGE_GREETINGS }

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
dndManager:Init { defaultCursor = CONFIG.DND.CURSOR }

--------------------------------------------------------------------------------
-- По алхимке поиск рецептов.
--------------------------------------------------------------------------------
local drumShiftMapper = DrumShiftMapper()
drumShiftMapper:Init( state, recipeService )

local searchAlgorithm = BacktrackingSearchAlgorithm()
searchAlgorithm:Init( RecipeEvaluator() )

local searchService = AlchemySearchService()
searchService:Init( state, recipeService, drumShiftMapper, searchAlgorithm )

--------------------------------------------------------------------------------
-- Виджеты.
--------------------------------------------------------------------------------
local wtPanel = _G.mainForm:GetChildChecked( "Panel" )
local wtOuText = wtPanel:GetChildChecked( "ouText" )

local widgetAlchemyV2 = WidgetAlchemyV2() -- Всё что изменяется кастомно внутри окна AlchemyV2
widgetAlchemyV2:Init( common.GetAddonMainForm( "AlchemyV2" ) )

--------------------------------------------------------------------------------
-- Всё что связано с текстом, почти.
--------------------------------------------------------------------------------
local textContainerService = AlchemyTextContainerService { _wtTextContainer = wtOuText }
textContainerService:Init { sizePadding = CONFIG.GUI.PADDING }

local textFormatter = AlchemyTextFormatter()
textFormatter:Init( widgetAlchemyV2, templateService )

local viewService = AlchemyViewService()
viewService:Init {
    textContainer = textContainerService,
    locale        = localeService,
    formatter     = textFormatter,
}

--------------------------------------------------------------------------------
-- Логика в событиях связано с алхимкой.
--------------------------------------------------------------------------------
local alchemyEvents = AlchemyEvents()
alchemyEvents:Init {
    state  = state,
    view   = viewService,
    search = searchService,
    recipe = recipeService,
    debug  = debugService,
}

local avatarEvents = AlchemyAvatarEvents { _wtMovable = wtPanel }
avatarEvents:Init {
    state     = state,
    AlchemyV2 = widgetAlchemyV2,
    view      = viewService,
    debug     = debugService,
    dnd       = dndManager,
}

--------------------------------------------------------------------------------
-- Регистрация событий.
--------------------------------------------------------------------------------
local events = {
    -- Алхимия
    EVENT_ALCHEMY_STARTED = function() alchemyEvents:OnStarted() end, -- Окно алхимки открывается. Инициализируется HELLO сообщение и кэш рецептов.
    EVENT_ALCHEMY_CANCELED = function( params ) alchemyEvents:OnCanceled( params ) end, -- Окно алхимки закрывается / вышли из варки в меню.
    EVENT_ALCHEMY_ITEM_PLACED = function( params ) alchemyEvents:OnItemPlaced( params ) end, -- При каждом изменении слота для компонентов уведомляет, что в такой-то слот был вставлен/вынут компонент.
    EVENT_ALCHEMY_REACTION_FINISHED = function() alchemyEvents:OnReactionFinished() end, -- Уведомляет о начале варки зелья. Хоть и название события говорит о другом...
    EVENT_ALCHEMY_RECIPES_CHANGED = function() alchemyEvents:OnRecipesChanged() end, -- Уведомляет об необходимости обновить список рецептов.
    
    -- Аватар
    EVENT_AVATAR_CREATED = function() avatarEvents:OnAvatarCreated() end, -- Инициализация логики. Когда игрок уже в игре, ТОЛЬКО ТОГДА необходимо применинить следующую логику.
    EVENT_AVATAR_ITEM_TAKEN = function( params ) avatarEvents:OnItemTaken( params ) end, -- Всё что попало в сумку игрока от крафта алхимки.

    -- Обновляет размеры Panel при изменении размера окна игры.
    -- Причина:
    -- 1) Закомментить этот ивент.
    -- 2) В игре - Меню -> Графика -> выставить Режим: "Оконный"
    -- 3) Изменять размер окна игры.
    -- Результат: Часть текста смещается и скрывается, а padding отступы превращаются невалидными.
    -- DnDManager не знает как работать с текстовым контейнером, если смотреть на опцию padding.
    EVENT_POS_CONVERTER_CHANGED = function()
        local exactHeight = textContainerService:GetExactTextHeight()
        textContainerService:UpdateSizePanel( exactHeight )
    end,
}

for eventName, handler in pairs( events ) do
    common.RegisterEventHandler( handler, eventName )
end

--------------------------------------------------------------------------------
-- Повторно событие EVENT_AVATAR_CREATED не прийдет, т.к. аватар уже находиться в игре.
-- Если аддон по каким-то причинам load/reload.
--------------------------------------------------------------------------------
if avatar.IsExist() then
    avatarEvents:OnAvatarCreated()
end