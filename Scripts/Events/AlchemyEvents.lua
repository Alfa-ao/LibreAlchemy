-- Events/AlchemyEvents.lua
-- Класс отвечающий за события EVENT_ALCHEMY_*.

Class( "AlchemyEvents", EventClassInterface() )

function AlchemyEvents:Init( state, config, widgetMgr, textFmt, services )
    self._state    = state
    self._config   = config
    self._ui       = widgetMgr
    self._text     = textFmt
	self._services = services
end

function AlchemyEvents:GetEventMap() --- table
    return {
        EVENT_ALCHEMY_STARTED           = self.OnStarted,
        EVENT_ALCHEMY_CANCELED          = self.OnCanceled,
        EVENT_ALCHEMY_ITEM_PLACED       = self.OnItemPlaced,
        EVENT_ALCHEMY_REACTION_FINISHED = self.OnReactionFinished,
        EVENT_ALCHEMY_RECIPES_CHANGED   = self.OnRecipesChanged,
    }
end

-- Событие дергает только при открытии окна Алхимии.
function AlchemyEvents:OnStarted() --- void
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_STARTED" )
	
    self._ui:Show()
    self._state.active = true
    
    -- Более логично подготовить весь список зелий (250) при открытии Алхимии.
    -- Но и оставить в CountPotential(), если список поменялся во время работы.
    self._services.recipe:CreateRecipeCache()

    if self._state.messageType == self._config.MESSAGE_WELCOME_BACK then
        self._text:SetText( self._services.locale:Get( "WELCOME_BACK" ) )
    elseif self._state.messageType == self._config.MESSAGE_GREETINGS then
        self._text:SetText( self._services.locale:Get( "GREETINGS" ) )
    end
end

function AlchemyEvents:OnCanceled( params ) --- void
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_CANCELED" )
    self._services.debug:LogGeneral( "isSuccess:", tostring( params.isSuccess ) )
	
    if not params.isSuccess then
        self._ui:Hide()
        self._state:ResetPlace()
        self._state.reactionSuccess = false
        self._state.active = false
        self._state.messageType = self._config.MESSAGE_WELCOME_BACK
    end
end

function AlchemyEvents:OnItemPlaced( params ) --- void
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_ITEM_PLACED" )
    self._services.debug:LogGeneral( function () 
        if params.placed then 
            return self._services.locale:Get( "DEBUG_INSERT_BAR" )
        end
        
        return self._services.locale:Get( "DEBUG_REMOVED_BAR" ) 
    end )
    self._services.debug:LogGeneral( tostring( params.slot ) )

    self._state.place.placed = params.placed
    self._state.place.readyNotFoundMessage = false

    if not params.placed then
        self._state.reactionSuccess = false
        self._state.place.count = 0
        return
    end

    self._state.place.count = self._state.place.count + 1

    if self._state.messageType ~= self._config.MESSAGE_NORMAL then return end

    if not self._state.reactionSuccess then
        local rc, dc = self._services.recipe:CountPotential()
        if rc > 0 and self._state.place.count == dc then
            self._text:SetText( string.format( self._services.locale:Get( "COUNT_RECIPLES" ), rc ) )
        elseif self._state.place.count == dc then
            self._text:SetText( self._services.locale:Get( "COMPONENTS_NOT_READY" ) )
        end
    end
end

function AlchemyEvents:OnReactionFinished() --- void
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_REACTION_FINISHED" )

    local found = self._services.search:FindBestRecipes()

    if #found == 0 then
        self._services.debug:LogReaction( "EVENT_ALCHEMY_REACTION_FINISHED:{empty}" )
        self._text:SetText( self._services.locale:Get( "RESULT_GIBBERISH" ) )
        self._state.reactionSuccess = false
    else
		self._services.debug:LogReaction( function() 
            return self._text:FormatResultsForLog( found, self._config.MAX_DISPLAY_RESULTS, self._state.drumsCount ) 
        end )
		
        self._text:SetText( self._text:FormatResults( found, self._config.MAX_DISPLAY_RESULTS, self._state.drumsCount ) )
        self._state.reactionSuccess = true
    end
end

function AlchemyEvents:OnRecipesChanged() --- void
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_RECIPLES_CHANGED" )
	
    self._state:ResetRecipeCache()
    self._text:SetText( self._services.locale:Get( "CONGRATULATION" ) )
    self._state.messageType = self._config.MESSAGE_WELCOME_BACK
end