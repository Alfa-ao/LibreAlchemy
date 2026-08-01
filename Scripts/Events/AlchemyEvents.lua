--------------------------------------------------------------------------------
-- Events/AlchemyEvents.lua
-- Класс, отвечающий за обработку событий алхимии (EVENT_ALCHEMY_*).
-- Отслеживает события действий в окне алхимии: открытие, закрытие,
-- размещение компонентов, начало реакции варки и изменение списка рецептов.
--------------------------------------------------------------------------------

Class( "AlchemyEvents", EventClassInterface() )

--------------------------------------------------------------------------------
--- Инициализация
--- @param state table AlchemyState
--- @param config table AlchemyConfig
--- @param widgetMgr table AlchemyWidgetManager
--- @param textFmt table AlchemyTextFormatter
--- @param services table Services
--------------------------------------------------------------------------------
function AlchemyEvents:Init( state, config, widgetMgr, textFmt, services ) --- void
    self._state    = state      -- AlchemyState - глобальное состояние аддона.
    self._config   = config     -- AlchemyConfig - конфигурация аддона.
    self._ui       = widgetMgr  -- AlchemyWidgetManager - менеджер UI виджетов.
    self._text     = textFmt    -- AlchemyTextFormatter - форматировщик текста.
    self._services = services   -- table - сервисы.
end

--------------------------------------------------------------------------------
--- Маппинг событий.
--- Возвращает таблицу соответствия имен событий методам-обработчикам.
--- Используется AlchemyEventManager для автоматической регистрации.
--- @return table
--------------------------------------------------------------------------------
function AlchemyEvents:GetEventMap()
    return {
        EVENT_ALCHEMY_STARTED           = self.OnStarted,           -- Открытие окна алхимии.
        EVENT_ALCHEMY_CANCELED          = self.OnCanceled,          -- Закрытие окна или переход в меню рецептов.
        EVENT_ALCHEMY_ITEM_PLACED       = self.OnItemPlaced,        -- Размещение/извлечение компонента в слотах.
        EVENT_ALCHEMY_REACTION_FINISHED = self.OnReactionFinished,  -- Начало варки.
        EVENT_ALCHEMY_RECIPES_CHANGED   = self.OnRecipesChanged,    -- Изменение списка рецептов.
    }
end

--------------------------------------------------------------------------------
-- Обработчики событий
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Обработчик события EVENT_ALCHEMY_STARTED.
-- Срабатывает при открытии окна алхимии. Инициализирует UI и кэширует рецепты.
--------------------------------------------------------------------------------
function AlchemyEvents:OnStarted() --- void
    ----------------------------------------
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_STARTED" )
    ----------------------------------------

    -- Показываем окно аддона и помечаем состояние как активное
    self._ui:Show()
    self._state.active = true

    -- Создаем кэш всех доступных рецептов.
    -- Более логично подготовить весь список зелий (около 250) именно при открытии Алхимии,
    -- чтобы не делать это при каждом размещении компонента.
    -- (Также продублировано в CountPotential() на случай, если список поменяется во время работы).
    self._services.recipe:CreateRecipeCache()

    -- Выводим приветственное сообщение в зависимости от предыдущего состояния
    if self._state.messageType == self._config.MESSAGE_WELCOME_BACK then
        self._text:SetText( self._services.locale:Get( "WELCOME_BACK" ) )
    elseif self._state.messageType == self._config.MESSAGE_GREETINGS then
        self._text:SetText( self._services.locale:Get( "GREETINGS" ) )
    end
    
    self._state.taskRefs.funcAlchemyStarted = common.DelayedCall( 100, function()
        if self._state.active then
            self._state.messageType = self._config.MESSAGE_NORMAL
        end
        
        self._state.taskRefs.funcAlchemyStarted = nil
    end )
end

--------------------------------------------------------------------------------
--- Обработчик события EVENT_ALCHEMY_CANCELED.
--- Срабатывает при закрытии окна алхимии или переход в меню рецептов.
--- true: вышли в меню рецептов.
--- false: закрыли окно алхимии.
--- @param params table { isSuccess: boolean }
--------------------------------------------------------------------------------
function AlchemyEvents:OnCanceled( params ) --- void
    self._state:ResetPlace() -- Сбрасываем состояние слотов
    
    -- Fix: 17.0.01.37 isSuccess (number(0/1))
    if params.isSuccess == false or params.isSuccess == 0 or params.isSuccess == nil then
        self._ui:Hide()
        self._state:ResetActive() -- Сброс состояния при закрытии алхимки.
        
        -- При следующем открытии покажем сообщение "С возвращением!"
        self._state.messageType = self._config.MESSAGE_WELCOME_BACK
    end
    
    ----------------------------------------
    self._services.debug:LogGeneral( 
        "EVENT_ALCHEMY_CANCELED", "isSuccess:", params.isSuccess,
        "Count place:", self._state.place.count
    )
    ----------------------------------------
end

--------------------------------------------------------------------------------
--- Обработчик события EVENT_ALCHEMY_ITEM_PLACED.
--- Срабатывает при размещении или извлечении предмета из слота рецепта.
--- @param params table { placed: boolean, slot: number }
--------------------------------------------------------------------------------
function AlchemyEvents:OnItemPlaced( params ) --- void
    ----------------------------------------
    -- Логируем действие (положен или вынут предмет)
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_ITEM_PLACED", function ()
        if params.placed then
            return userMods.FromWString( self._services.locale:Get( "DEBUG_INSERT_BAR" ) )
        end
        
        return userMods.FromWString( self._services.locale:Get( "DEBUG_REMOVED_BAR" ) )
    end, "Slot:", params.slot )
    ----------------------------------------
    
    -- Обновляем состояние слотов
    self._state.place.placed = params.placed

    -- Логика подсчета заполненных слотов
    if params.placed then
        self._state.place.count = self._state.place.count + 1
    else
        self._state.reactionSuccess = false
        self._state.place.count = self._state.place.count - 1
    end
    
    ----------------------------------------
    self._services.debug:LogGeneral( "Count place:", self._state.place.count )
    ----------------------------------------
    
    -- Если сейчас не стандартный режим отображения, не обновляем текст
    -- Автоматически переключится. См. (AlchemyEvents:OnStarted)
    if self._state.messageType ~= self._config.MESSAGE_NORMAL then return end
    
    
    local funcGetMessage = function()
        self._state.taskRefs.funcAlchemyItemPlaced = nil
        
        -- Если мы не варим, пытаемся оценить возможные рецепты
        if not self._state.reactionSuccess then
            -- Получаем кол-во возможных рецептов (countRecipe) и кол-во требуемых слотов (filledDrumsCount)
            local countRecipe, filledDrumsCount = self._services.recipe:CountPotential()
            
            -- Если все слоты заполнены и есть подходящие рецепты
            if countRecipe > 0 then
                -- Сопоставляется локализованный шаблон со значением и пушится в текстовый контейнер
                local vtCountRecipes = common.CreateValuedText{
                    format = self._services.locale:Get( "COUNT_RECIPES" ),
                    count = countRecipe,
                }
                
                self._text:SetText( vtCountRecipes )
            -- Если до сих пор рецептов нет, но слоты частично заполнены
            elseif self._state.place.count > 0 then
                self._text:SetText( self._services.locale:Get( "COMPONENTS_NOT_READY" ) )
            -- Ни одного слота не заполнено
            else
                self._text:SetText( self._services.locale:Get( "NOT_FOUND_RECIPES" ) )
            end
        end
    end
    
    -- Отменяем предыдущий таймер, если он уже был запланирован
    if self._state.taskRefs.funcAlchemyItemPlaced ~= nil then
        common.CancelDelayedCall( self._state.taskRefs.funcAlchemyItemPlaced )
    end

    -- Планируем новый отложенный вызов и сохраняем его идентификатор
    self._state.taskRefs.funcAlchemyItemPlaced = common.DelayedCall( 100, funcGetMessage )
end

--------------------------------------------------------------------------------
-- Обработчик события EVENT_ALCHEMY_REACTION_FINISHED.
-- Срабатывает сразу после начала процесса варки (нажатие кнопки "варить").
--------------------------------------------------------------------------------
function AlchemyEvents:OnReactionFinished() --- void
    ----------------------------------------
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_REACTION_FINISHED" )
    ----------------------------------------
    
    -- Запускаем алгоритм поиска подходящих рецептов
    local found = self._services.search:FindBestRecipes()
    
    -- Если ничего не найдено
    if #found == 0 then
        ----------------------------------------
        self._services.debug:LogReaction( "EVENT_ALCHEMY_REACTION_FINISHED:{empty}" )
        ----------------------------------------
        
        -- Ничего нет кроме бормотухи
        self._text:SetText( self._services.locale:Get( "RESULT_GIBBERISH" ) )
        self._state.reactionSuccess = false
    else
        ----------------------------------------
        -- Log: EVENT_ALCHEMY_REACTION_FINISHED:123,1,-1,0,0,0,зелье|123,...
        self._services.debug:LogReaction( function()
            return self._text:FormatResultsForLog( found, self._config.MAX_DISPLAY_RESULTS, self._state.drumsCount )
        end )
        ----------------------------------------
        
        -- Выводим ТОП-N результатов
        self._text:DisplayResults( found, self._config.MAX_DISPLAY_RESULTS, self._state.drumsCount )

        -- Помечаем реакцию как успешную (чтобы при получении предмета показать поздравление с кол-вом полученного предмета)
        self._state.reactionSuccess = true
    end
end

--------------------------------------------------------------------------------
-- Обработчик события EVENT_ALCHEMY_RECIPES_CHANGED.
-- Срабатывает, когда список рецептов изменился.
--------------------------------------------------------------------------------
function AlchemyEvents:OnRecipesChanged() --- void
    ----------------------------------------
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_RECIPES_CHANGED" )
    ----------------------------------------
    
    -- Сбрасываем кэш рецептов для обновления
    self._state:ResetRecipeCache()

    -- Поздравляем игрока.
    self._text:SetText( self._services.locale:Get( "CONGRATULATION" ) )
    
    -- отрубаем сообщения в EVENT_ALCHEMY_ITEM_PLACED
    -- Почему не MESSAGE_WARNING ? потому что, если переоткрыли алхимку, то сообщений никаких не было бы.
    -- А так, поздравление (работаем дальше с алхимкой) или Приветсвие (переоткрыли окно)
    self._state.messageType = self._config.MESSAGE_WELCOME_BACK
end