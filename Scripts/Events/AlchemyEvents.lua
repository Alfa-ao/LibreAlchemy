--------------------------------------------------------------------------------
-- Events/AlchemyEvents.lua
-- Класс, отвечающий за обработку событий алхимии (EVENT_ALCHEMY_*).
--------------------------------------------------------------------------------

Class( "AlchemyEvents" )

--------------------------------------------------------------------------------
--- @param context table -- Набор всякого всяческого
--------------------------------------------------------------------------------
function AlchemyEvents:Init( context )
    self._state         = context.state
    self._textContainer = context.textContainer
    self._formatter     = context.formatter
    self._search        = context.search
    self._recipe        = context.recipe
    self._debug         = context.debug
    self._locale        = context.locale
end

--------------------------------------------------------------------------------
-- Обработчик события EVENT_ALCHEMY_STARTED.
-- Срабатывает при открытии окна алхимии.
--------------------------------------------------------------------------------
function AlchemyEvents:OnStarted()
    ----------------------------------------
    self._debug:LogGeneral( "EVENT_ALCHEMY_STARTED" )
    ----------------------------------------

    -- Показывает окно подсказки и помечает состояние как активное
    _G.mainForm:Show( true )
    self._state.active = true

    -- Создает кэш всех доступных рецептов.
    self._recipe:CreateRecipeCache()

    -- Выводит HELLO сообщение в зависимости от предыдущего состояния
    if self._state.messageType == CONFIG.MESSAGE_WELCOME_BACK then
        self._textContainer:SetLines( self._locale:Get( "WELCOME_BACK" ) )
        ----------------------------------------
        self._debug:LogGeneral( "WELCOME_BACK" )
        ----------------------------------------
    elseif self._state.messageType == CONFIG.MESSAGE_GREETINGS then
        self._textContainer:SetLines( self._locale:Get( "GREETINGS" ) )
        ----------------------------------------
        self._debug:LogGeneral( "GREETINGS" )
        ----------------------------------------
    end
end

--------------------------------------------------------------------------------
--- Обработчик события EVENT_ALCHEMY_CANCELED.
--- Срабатывает при закрытии окна алхимии или переход в меню рецептов.
--- true: вышли в меню рецептов.
--- false: закрыли окно алхимии. Вроде и при прерывании (не забрал результат) - проверить.
--- @param params table { isSuccess: boolean }
--------------------------------------------------------------------------------
function AlchemyEvents:OnCanceled( params )
    self._state:ResetPlace() -- Сбрасывает состояние слотов
    
    -- Fix: 17.0.01.37 isSuccess (number(0/1))
    if params.isSuccess == false or params.isSuccess == 0 or params.isSuccess == nil then
        _G.mainForm:Show( false )
        self._state:ResetActive() -- Сброс состояния при закрытии алхимки.
        
        -- При следующем открытии покажет сообщение "С возвращением!"
        self._state.messageType = CONFIG.MESSAGE_WELCOME_BACK
    end
    
    ----------------------------------------
    self._debug:LogGeneral(
        "EVENT_ALCHEMY_CANCELED",
        "isSuccess:",
        params.isSuccess,
        "Count place:",
        self._state.place.count
    )
    ----------------------------------------
end

--------------------------------------------------------------------------------
--- Обработчик события EVENT_ALCHEMY_ITEM_PLACED.
--- Срабатывает при размещении или извлечении предмета из слота рецепта.
--- @param params table { placed: boolean, slot: number }
--------------------------------------------------------------------------------
function AlchemyEvents:OnItemPlaced( params )
    ----------------------------------------
    self._debug:LogGeneral( "EVENT_ALCHEMY_ITEM_PLACED", function ()
        if params.placed then
            return "DEBUG_INSERT_BAR"
        end
        
        return "DEBUG_REMOVED_BAR"
    end, "Slot:", params.slot )
    ----------------------------------------
    
    -- Обновляет состояние слотов
    self._state.place.placed = params.placed

    -- Логика подсчета заполненных слотов
    if params.placed then
        self._state.place.count = self._state.place.count + 1
    else
        self._state.reactionSuccess = false
        self._state.place.count = self._state.place.count - 1
    end
    
    ----------------------------------------
    self._debug:LogGeneral( "Count place:", self._state.place.count )
    ----------------------------------------
    
    -- Если сейчас не стандартный режим отображения, не обновлять текст.
    -- Автоматически переключится.
    if self._state.messageType ~= CONFIG.MESSAGE_NORMAL then
        if self._state.taskRefs.funcAlchemyStarted == nil then
            self._state.taskRefs.funcAlchemyStarted = common.DelayedCall( 100, function()
                if self._state.active then
                    self._state.messageType = CONFIG.MESSAGE_NORMAL
                    ----------------------------------------
                    self._debug:LogGeneral( "MESSAGE_TYPE change to default" )
                    ----------------------------------------
                end
                
                self._state.taskRefs.funcAlchemyStarted = nil
            end )
        end
        
        return
    end
    
    
    local funcGetMessage = function()
        self._state.taskRefs.funcAlchemyItemPlaced = nil
        
        -- Если не варим (в меню варки), то оценить возможные рецепты
        if not self._state.reactionSuccess then
            -- Кол-во возможных рецептов (countRecipe) и кол-во требуемых слотов (filledDrumsCount)
            local countRecipe, _ = self._recipe:CountPotential()
            
            -- Если все слоты заполнены и есть подходящие рецепты
            if countRecipe > 0 then
                -- Сопоставляется шаблон со значением и пушится в текстовый контейнер
                local vtCountRecipes = common.CreateValuedText{
                    format = self._locale:Get( "COUNT_RECIPES" ),
                    count = countRecipe,
                }
                
                self._textContainer:SetLines( vtCountRecipes )
                ----------------------------------------
                self._debug:LogGeneral( "COUNT_RECIPES", countRecipe )
                ----------------------------------------
            -- Если до сих пор рецептов нет, но слоты частично заполнены
            elseif self._state.place.count > 0 then
                self._textContainer:SetLines( self._locale:Get( "COMPONENTS_NOT_READY" ) )
                ----------------------------------------
                self._debug:LogGeneral( "COMPONENTS_NOT_READY" )
                ----------------------------------------
            -- Ни одного слота не заполнено
            else
                self._textContainer:SetLines( self._locale:Get( "NOT_FOUND_RECIPES" ) )
                ----------------------------------------
                self._debug:LogGeneral( "NOT_FOUND_RECIPES" )
                ----------------------------------------
            end
        end
    end
    
    -- Отменяет предыдущий таймер, если он уже был запланирован
    if self._state.taskRefs.funcAlchemyItemPlaced ~= nil then
        common.CancelDelayedCall( self._state.taskRefs.funcAlchemyItemPlaced )
    end

    -- Запланировать новый отложенный вызов и сохранить его идентификатор
    self._state.taskRefs.funcAlchemyItemPlaced = common.DelayedCall( 100, funcGetMessage )
end

--------------------------------------------------------------------------------
-- Обработчик события EVENT_ALCHEMY_REACTION_FINISHED.
-- Срабатывает сразу после начала процесса варки (нажатие кнопки "варить").
--------------------------------------------------------------------------------
function AlchemyEvents:OnReactionFinished() --- void
    ----------------------------------------
    self._debug:LogGeneral( "EVENT_ALCHEMY_REACTION_FINISHED" )
    ----------------------------------------
    
    -- Запускает алгоритм поиска подходящих рецептов
    local found = self._search:FindBestRecipes()
    
    -- Если ничего не найдено
    if #found == 0 then
        ----------------------------------------
        self._debug:LogReaction( "EVENT_ALCHEMY_REACTION_FINISHED:{empty}" )
        ----------------------------------------
        
        -- Ничего нет кроме бормотухи
        self._textContainer:SetLines( self._locale:Get( "RESULT_GIBBERISH" ) )
        self._state.reactionSuccess = false
    else
        ----------------------------------------
        -- Log: EVENT_ALCHEMY_REACTION_FINISHED:123,1,-1,0,0,0,зелье|123,...
        self._debug:LogReaction( function()
            return self._formatter:FormatResultsForLog( found, CONFIG.MAX_DISPLAY_RESULTS, self._state.drumsCount )
        end )
        ----------------------------------------
        
        -- Вывод ТОП-N результатов
        local linesData = self._formatter:FormatResults( found, CONFIG.MAX_DISPLAY_RESULTS, self._state.drumsCount )
	    self._textContainer:SetLines( table.unpack( linesData ) )
        
        -- Присваивается метка реакции как успешную (чтобы при получении предмета показать поздравление с кол-вом полученного предмета)
        self._state.reactionSuccess = true
    end
end

--------------------------------------------------------------------------------
-- Обработчик события EVENT_ALCHEMY_RECIPES_CHANGED.
-- Срабатывает, когда список рецептов изменился.
--------------------------------------------------------------------------------
function AlchemyEvents:OnRecipesChanged() --- void
    ----------------------------------------
    self._debug:LogGeneral( "EVENT_ALCHEMY_RECIPES_CHANGED" )
    ----------------------------------------
    
    -- Сбрасывает кэш рецептов для обновления
    self._state:ResetRecipeCache()
	
	-- Заглушка если алхимка не открыта, но взяли допустим рецепт из Айрина и добавили зелье в рецепт.
	if not self._state.active then
		return
	end
	
    -- Поздравить игрока.
    self._textContainer:SetLines( self._locale:Get( "CONGRATULATION" ) )
    
    -- Отрубить сообщения в EVENT_ALCHEMY_ITEM_PLACED
    -- поздравление (работаем дальше с алхимкой) или Приветсвие (переоткрыли окно)
    self._state.messageType = CONFIG.MESSAGE_WELCOME_BACK
end