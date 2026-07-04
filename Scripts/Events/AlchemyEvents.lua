--------------------------------------------------------------------------------
-- Events/AlchemyEvents.lua
-- Класс, отвечающий за обработку событий алхимии (EVENT_ALCHEMY_*).
-- Управляет жизненным циклом окна алхимии: открытие, закрытие,
-- размещение компонентов в барабанах, завершение реакции и изучение новых рецептов.
--------------------------------------------------------------------------------

Class( "AlchemyEvents", EventClassInterface() )

--------------------------------------------------------------------------------
-- Инициализация
--------------------------------------------------------------------------------
function AlchemyEvents:Init( state, config, widgetMgr, textFmt, services ) --- void
    self._state    = state      -- AlchemyState - глобальное состояние аддона.
    self._config   = config     -- AlchemyConfig - конфигурация аддона.
    self._ui       = widgetMgr  -- AlchemyWidgetManager - менеджер UI виджетов.
    self._text     = textFmt    -- AlchemyTextFormatter - форматировщик текста.
    self._services = services   -- table - набор сервисов (debug, locale, recipe, search и т.д.).
end

--------------------------------------------------------------------------------
-- Маппинг событий
--------------------------------------------------------------------------------

-- Возвращает таблицу соответствия имен событий методам-обработчикам.
-- Используется AlchemyEventManager для автоматической регистрации.
function AlchemyEvents:GetEventMap() --- table
    return {
        EVENT_ALCHEMY_STARTED           = self.OnStarted,           -- Открытие окна алхимии.
        EVENT_ALCHEMY_CANCELED          = self.OnCanceled,          -- Отмена или неудачное завершение варки.
        EVENT_ALCHEMY_ITEM_PLACED       = self.OnItemPlaced,        -- Размещение/извлечение компонента в барабане.
        EVENT_ALCHEMY_REACTION_FINISHED = self.OnReactionFinished,  -- Завершение химической реакции (крафт).
        EVENT_ALCHEMY_RECIPES_CHANGED   = self.OnRecipesChanged,    -- Изменение списка доступных рецептов (изучение нового).
    }
end

--------------------------------------------------------------------------------
-- Обработчики событий
--------------------------------------------------------------------------------

-- Обработчик события EVENT_ALCHEMY_STARTED.
-- Срабатывает при открытии окна алхимии. Инициализирует UI и кэширует рецепты.
function AlchemyEvents:OnStarted() --- void
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_STARTED" )
    
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
end

--------------------------------------------------------------------------------

-- Обработчик события EVENT_ALCHEMY_CANCELED.
-- Срабатывает при закрытии окна алхимии или отмене варки.
function AlchemyEvents:OnCanceled( params ) --- void
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_CANCELED" )
    self._services.debug:LogGeneral( "isSuccess:", tostring( params.isSuccess ) )
    
    -- Если варка не удалась или окно просто закрыли (isSuccess == false)
    if params.isSuccess == false or params.isSuccess == 0 or params.isSuccess == nil then
        self._ui:Hide()
        self._state:ResetPlace()            -- Сбрасываем состояние слотов
        self._state.reactionSuccess = false -- Сбрасываем флаг успешной реакции
        self._state.active = false          -- Помечаем аддон как неактивный
        -- При следующем открытии покажем сообщение "С возвращением!"
        self._state.messageType = self._config.MESSAGE_WELCOME_BACK
    end
end

--------------------------------------------------------------------------------

-- Обработчик события EVENT_ALCHEMY_ITEM_PLACED.
-- Срабатывает при размещении или извлечении предмета из барабана (ступки).
function AlchemyEvents:OnItemPlaced( params ) --- void
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_ITEM_PLACED" )
    
    -- Логируем действие (положен или вынут предмет)
    self._services.debug:LogGeneral( function () 
        if params.placed then 
            return self._services.locale:Get( "DEBUG_INSERT_BAR" )
        end
        return self._services.locale:Get( "DEBUG_REMOVED_BAR" ) 
    end )
    self._services.debug:LogGeneral( tostring( params.slot ) )
    
    -- Обновляем состояние слотов
    self._state.place.placed = params.placed
    self._state.place.readyNotFoundMessage = false

    -- Если предмет вынут, сбрасываем счетчики и выходим
    if not params.placed then
        self._state.reactionSuccess = false
        self._state.place.count = 0
        return
    end

    -- Увеличиваем счетчик заполненных слотов
    self._state.place.count = self._state.place.count + 1

    -- Если сейчас не стандартный режим отображения, не обновляем текст
    if self._state.messageType ~= self._config.MESSAGE_NORMAL then return end
    
    -- Если реакция еще не завершилась успешно, пытаемся оценить потенциальные рецепты
    if not self._state.reactionSuccess then
        -- Получаем кол-во потенциальных рецептов (countRecipe) и кол-во заполненных слотов (filledDrumsCount)
        local countRecipe, filledDrumsCount = self._services.recipe:CountPotential()
        
        -- Если все слоты заполнены и есть подходящие рецепты
        if countRecipe > 0 --[[and self._state.place.count == filledDrumsCount]] then
            self._text:SetText( string.format( self._services.locale:Get( "COUNT_RECIPLES" ), countRecipe ) )
        -- Если все слоты заполнены, но подходящих рецептов нет (компоненты не те)
        elseif self._state.place.count == filledDrumsCount then
            self._text:SetText( self._services.locale:Get( "COMPONENTS_NOT_READY" ) )
        end
    end
end

--------------------------------------------------------------------------------

-- Обработчик события EVENT_ALCHEMY_REACTION_FINISHED.
-- Срабатывает после завершения процесса варки (нажатия кнопки "Создать").
-- Запускает поиск лучших рецептов с учетом сдвигов барабанов.
function AlchemyEvents:OnReactionFinished() --- void
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_REACTION_FINISHED" )

    -- Запускаем алгоритм поиска подходящих рецептов
    local found = self._services.search:FindBestRecipes()

    -- Если ничего не найдено (получилась "бормотуха")
    if #found == 0 then
        self._services.debug:LogReaction( "EVENT_ALCHEMY_REACTION_FINISHED:{empty}" )
        self._text:SetText( self._services.locale:Get( "RESULT_GIBBERISH" ) )
        self._state.reactionSuccess = false
    else
        -- Логируем найденные варианты (сдвиги и названия)
        self._services.debug:LogReaction( function() 
            return self._text:FormatResultsForLog( found, self._config.MAX_DISPLAY_RESULTS, self._state.drumsCount ) 
        end )
        
        -- Выводим ТОП-N результатов в UI
        self._text:DisplayResults( found, self._config.MAX_DISPLAY_RESULTS, self._state.drumsCount )
        
        -- Помечаем реакцию как успешную (чтобы при получении предмета показать поздравление)
        self._state.reactionSuccess = true
    end
end

--------------------------------------------------------------------------------

-- Обработчик события EVENT_ALCHEMY_RECIPES_CHANGED.
-- Срабатывает, когда игрок изучает новый рецепт алхимии.
function AlchemyEvents:OnRecipesChanged() --- void
    self._services.debug:LogGeneral( "EVENT_ALCHEMY_RECIPES_CHANGED" )
    
    -- Сбрасываем кэш рецептов, чтобы при следующем открытии он обновился
    self._state:ResetRecipeCache()
    
    -- Поздравляем игрока и устанавливаем флаг для вывода "С возвращением!" при следующем входе
    self._text:SetText( self._services.locale:Get( "CONGRATULATION" ) )
    self._state.messageType = self._config.MESSAGE_WELCOME_BACK
end