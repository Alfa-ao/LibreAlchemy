-- Core/AlchemyInit.lua

local config = AlchemyConfig()
local state  = AlchemyState()
state.messageType = config.MESSAGE_GREETINGS

-- Инструменты
local mathUtils = MathUtils()

-- Сервисы
local services = { 
	debug = AlchemyDebugService(),   -- Сервис для отладки (Debug)
	locale = AlchemyLocaleService(), -- Сервис локализации ENG, RUS
	recipe = AlchemyRecipeService(), -- Сервис рецепта
	search = AlchemySearchService(), -- Сервис поиска возможных рецептов
}

services.debug:Init( config )
services.recipe:Init( state )

----------------------------------
local drumShiftMapper = DrumShiftMapper()             -- Маппер сдвигов барабанов
local searchAlgorithm = BacktrackingSearchAlgorithm() -- Алгоритм сервиса search

drumShiftMapper:Init( state, services.recipe, mathUtils )
searchAlgorithm:Init( RecipeEvaluator(), mathUtils )
services.search:Init( state, services.recipe, drumShiftMapper, searchAlgorithm )
----------------------------------

-- Интерфейс
local widgetManager = AlchemyWidgetManager()
widgetManager:Init( WidgetOuText(), WidgetDnD(), WidgetRollsBar() ) 

local textFormatter = AlchemyTextFormatter()
textFormatter:Init( widgetManager, services.debug )

-- Обработчики событий
local systemEvents = AlchemySystemEvents()
local alchemyEvents = AlchemyEvents()      -- EVENT_ALCHEMY_*
local avatarEvents = AlchemyAvatarEvents() -- EVENT_AVATAR_*
systemEvents:Init( state, config, textFormatter, services )
alchemyEvents:Init( state, config, widgetManager, textFormatter, services )
avatarEvents:Init( state, config, widgetManager, textFormatter, services )

-- Регистрация событий
local eventManager = AlchemyEventManager()
eventManager:Init( systemEvents, alchemyEvents, avatarEvents )
eventManager:RegisterAll()

-- Инициализация
local bootstrap = AlchemyBootstrap()
bootstrap:Init( eventManager )
bootstrap:Run()
