-- AlchemyInit.lua

local config = AlchemyConfig()
local state  = AlchemyState()
state.messageType = config.MESSAGE_GREETINGS

-- Сервисы
local services = { 
	debug = AlchemyDebugService(),
	locale = AlchemyLocaleService(), 
	recipe = AlchemyRecipeService(), 
	search = AlchemySearchService(), 
}

services.debug:Init( config )
services.recipe:Init( state )
services.search:Init( state, services.recipe )

-- Интерфейс
local widgetManager = AlchemyWidgetManager()
local textFormatter = AlchemyTextFormatter()

textFormatter:Init( widgetManager, services.debug )

-- Обработчики событий
local systemEvents = AlchemySystemEvents()
local alchemyEvents = AlchemyEvents()
local avatarEvents = AlchemyAvatarEvents()

systemEvents:Init( state, config, textFormatter, services )
alchemyEvents:Init( state, config, widgetManager, textFormatter, services )
avatarEvents:Init( state, config, widgetManager, textFormatter, services )

-- Регистрация событий
local eventBus = AlchemyEventBus()
eventBus:Init( systemEvents, alchemyEvents, avatarEvents )
eventBus:RegisterAll()

----------------------
if avatar.IsExist() then
	avatarEvents:OnAvatarCreated( --[[ { id = avatar.GetId() } ]] )
end
