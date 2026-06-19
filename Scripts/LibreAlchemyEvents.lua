--------------------------------------------------------------------------------
-- EVENTS
-- Обработчики событий.
--------------------------------------------------------------------------------

--- @function EVENT_SECOND_TIMER
--- @description Глобальный таймер (срабатывает раз в секунду).
--- Используется как механизм задержки (debounce) для корректного вывода сообщения "Тут нет рецептов", 
--- когда игрок извлек все компоненты из барабанов, но окно алхимии все еще открыто.
--- Флаг readyNotFoundMessage предотвращает спам этим сообщением каждый тик таймера.
--- Также сбрасывает флаг welcomeBack в nil, позволяя аддону перейти в штатный режим работы после приветствия.
_G.LibreAlchemy.events.EVENT_SECOND_TIMER = function()
	if _G.LibreAlchemy.active and _G.LibreAlchemy.place.placed == false and avatar.GetAlchemyInfo().active then
		if _G.LibreAlchemy.place.readyNotFoundMessage then
			_G.LibreAlchemy.fn.wSetText( _G.LibreAlchemy.locales.NOT_FOUND_RECIPLES )
			
			_G.LibreAlchemy.place.placed = nil
			_G.LibreAlchemy.place.readyNotFoundMessage = false
		else
			_G.LibreAlchemy.place.readyNotFoundMessage = true
		end
	end
	
	if _G.LibreAlchemy.active then
		_G.LibreAlchemy.welcomeBack = nil
	end
end

--- @function EVENT_AVATAR_ITEM_TAKEN
--- @description Срабатывает при получении предмета главным игроком.
--- В контексте данного аддона используется для перехвата результата успешной алхимической варки.
--- Проверяет тип действия (Craft) и флаг reactionSuccess, чтобы вывести поздравление 
--- с названием и количеством созданного зелья, игнорируя все остальные получения предметов.
--- @param params table - Параметры события.
--- @param params.itemObject ValuedObject - Объект, содержащий информацию о полученном предмете.
--- @param params.actionType string - Тип действия "ENUM_TakeItemActionType_Craft".
_G.LibreAlchemy.events.EVENT_AVATAR_ITEM_TAKEN = function( params )
	if _G.LibreAlchemy.debug then 
        common.LogInfo( "", "EVENT_AVATAR_ITEM_TAKEN" )
		common.LogInfo( "", params.actionType )
		common.LogInfo( "", "reactionSuccess: " .. tostring( _G.LibreAlchemy.reactionSuccess ) )
    end
	
	if params.actionType == "ENUM_TakeItemActionType_Craft" and _G.LibreAlchemy.reactionSuccess then
		local potionName = userMods.FromWString( itemLib.GetItemInfo( params.itemObject:GetId() ).name )
		local count = itemLib.GetStackInfo( params.itemObject:GetId() ).count
		_G.LibreAlchemy.fn.wSetText( string.format( _G.LibreAlchemy.locales.AVATAR_ITEM_TAKEN, potionName, count ) )
	end
end

--- @function EVENT_ALCHEMY_REACTION_FINISHED
--- @description Завершён (ПЕРВЫЙ) этап алхимической реакции.
--- Анализирует барабаны, запускает рекурсивный поиск всех комбинаций сдвигов,
--- сортирует найденные рецепты и выводит топ-N результатов в интерфейс.
_G.LibreAlchemy.events.EVENT_ALCHEMY_REACTION_FINISHED = function()
    if _G.LibreAlchemy.debug then 
        common.LogInfo( "", "EVENT_ALCHEMY_REACTION_FINISHED" ) 
    end
    
    -- Получаем данные из API
    local ainf = avatar.GetAlchemyInfo()
    local dri = avatar.GetAlchemyDrumInfo( 0 )
    
    -- Инициализация параметров сдвигов
    _G.LibreAlchemy.nSinshi = dri.maxCorrectionsPerColumn or _G.LibreAlchemy.nSinshi
    local nRota = ainf.correctionCount or 0
    _G.LibreAlchemy.nDrums = ainf.drumsCount or _G.LibreAlchemy.nDrums -- Актуализируем количество барабанов
    
    local lineMinus1, linePlus1 = nil, nil
    
    -- 3. Проверяем доступность дополнительных линий результата (-1 и 1)
    if avatar.IsAlchemyLineAvailable( -1 ) then lineMinus1 = {} end
    if avatar.IsAlchemyLineAvailable( 1 ) then linePlus1 = {} end
    
    -- 4. Анализируем барабаны и фильтруем рецепты
    _G.LibreAlchemy.fn.BuildComponentMapAndFilter()
    _G.LibreAlchemy.lFound = {}
    
    -- 5. Запускаем рекурсивный поиск всех комбинаций сдвигов
    for shiftsLeft = 0, nRota do 
        _G.LibreAlchemy.fn.RecursiveShiftSearch( _G.LibreAlchemy.nDrums, shiftsLeft, {}, {}, lineMinus1, linePlus1 )
    end
    
    -- 6. Обработка результатов
    if #_G.LibreAlchemy.lFound == 0 then
        if _G.LibreAlchemy.debugReaction then 
            common.LogInfo( "", "EVENT_ALCHEMY_REACTION_FINISHED:{empty}" ) 
        end
        
        _G.LibreAlchemy.fn.wSetText( _G.LibreAlchemy.locales.RESULT_GIBBERISH )
        _G.LibreAlchemy.reactionSuccess = false
    else
        -- Сортируем найденные рецепты по приоритету
        table.sort( _G.LibreAlchemy.lFound, function( a, b )
			if a.rc.score == b.rc.score then
				return a.rc.name > b.rc.name
			else
				return a.rc.score > b.rc.score
			end
		end )
        
        -- Таблицы для сбора частей строк
        local fmtParts = {} -- Для вывода в интерфейс
        local logParts = {} -- Для вывода в лог
        
        -- Формируем строки для вывода в интерфейс и лог, ограничиваемся топ-N рецептами (используем глобальную maxDisplay)
        for i = 1, math.min( #_G.LibreAlchemy.lFound, _G.LibreAlchemy.maxDisplay ) do
            local vr = _G.LibreAlchemy.lFound[i]
            
            -- Формируем строку сдвигов для интерфейса/лога
            local shiftStr = string.format( "%d", -vr.sh[1] )
            local logShiftStr = string.format( "%d", -vr.sh[1] )
            
            for dc = 2, _G.LibreAlchemy.nDrums do
                shiftStr = shiftStr .. string.format( " |% d", -vr.sh[dc] ) -- "% d" добавляет пробел перед положительными числами для выравнивания
                logShiftStr = logShiftStr .. string.format( ",%d", -vr.sh[dc] )
            end
            
            -- Добавляем отформатированную строку в таблицу для интерфейса/лога
            table.insert( fmtParts, string.format( "%d: %s - %s", vr.rc.score, shiftStr, vr.rc.name ) )
            table.insert( logParts, string.format( "%d,%s,%s", vr.rc.score, logShiftStr, vr.rc.name ) )
        end
        
        if _G.LibreAlchemy.debugReaction then 
            -- Результат: "EVENT_ALCHEMY_REACTION_FINISHED:1,0,0,0,0,0,Обычный пятновыводитель|1,1,0,0,0,0,Обычный пятновыводитель"
            common.LogInfo("", "EVENT_ALCHEMY_REACTION_FINISHED:" .. table.concat( logParts, "|" ) ) 
        end
		
        -- Результат: "120:  0 | 1 | 2 | 0 | 0 - Королевское зелье исцеления<br/>120:  0 | 0 | 1 |-1 |-1 - Королевское зелье восстановления"
        _G.LibreAlchemy.fn.wSetText( table.concat( fmtParts, "<br/>" ) )
        
        _G.LibreAlchemy.reactionSuccess = true
    end
end

--- @function EVENT_ALCHEMY_RECIPES_CHANGED
--- @description Изменился список алхимических рецептов главного игрока.
_G.LibreAlchemy.events.EVENT_ALCHEMY_RECIPES_CHANGED = function()
    if _G.LibreAlchemy.debug then common.LogInfo( "", "EVENT_ALCHEMY_RECIPES_CHANGED" ) end
	
	-- Сбрасываем кэш, чтобы при следующем запросе список рецептов обновился
    _G.LibreAlchemy.lReci = nil
    
	_G.LibreAlchemy.fn.wSetText( _G.LibreAlchemy.locales.CONGRATULATION )
	
	_G.LibreAlchemy.welcomeBack = true
end

--- @function _G.LibreAlchemy.events.EVENT_ALCHEMY_ITEM_PLACED
--- @description Обрабатывает событие помещения или извлечения алхимического компонента в барабан.
--- Отслеживает состояние слотов, обновляет внутренние счетчики и выводит пользователю 
--- предварительную оценку возможности создания рецептов на основе текущих компонентов.
--- @param params table Параметры события:
--- @param params.slot number Индекс слота (барабана), в котором произошло изменение (0-первый слот).
--- @param params.placed boolean true, если компонент помещен; false, если извлечен.
_G.LibreAlchemy.events.EVENT_ALCHEMY_ITEM_PLACED = function( params )
	if _G.LibreAlchemy.debug then
		common.LogInfo( "", "EVENT_ALCHEMY_ITEM_PLACED" )
		common.LogInfo( "", params.placed and _G.LibreAlchemy.locales.DEBUG_INSERT_BAR or _G.LibreAlchemy.locales.DEBUG_REMOVED_BAR )
		common.LogInfo( "", tostring( params.slot ) )
	end
	--[[
	Ивент EVENT_ALCHEMY_ITEM_PLACED отрабатывает
	При открытии алхимии:
	Info: EVENT_ALCHEMY_STARTED
	Info: EVENT_ALCHEMY_ITEM_PLACED
	Info: положен
	Info: 0
	Info: EVENT_ALCHEMY_ITEM_PLACED
	Info: положен
	Info: 1
	
	При выборе зелья:
	Info: EVENT_ALCHEMY_ITEM_PLACED
	Info: убран
	Info: 0
	Info: EVENT_ALCHEMY_ITEM_PLACED
	Info: убран
	Info: 1
	Info: EVENT_ALCHEMY_ITEM_PLACED
	Info: положен
	Info: 0
	Info: EVENT_ALCHEMY_ITEM_PLACED
	Info: положен
	Info: 1
	
	Сигналы при переключении на другое зелье:
	сначала полностью убирает слоты
	тут-же обратно ложит слоты

	Во время этих действий может легко влесть ивент EVENT_SECOND_TIMER
	]]
	
	_G.LibreAlchemy.place.placed = params.placed
	_G.LibreAlchemy.place.readyNotFoundMessage = false
	
	-- Если событие пришло с вынутым компонентом.
	-- Устанавливаем финишную реакцию ( даже если она не была EVENT_ALCHEMY_REACTION_FINISHED ) - false
	-- Ограничиваем выполнение дальнейшего кода
	if not params.placed then
		_G.LibreAlchemy.reactionSuccess = false
		_G.LibreAlchemy.place.count = 0 -- Присваиваем 0, ведь по логике компоненты сначала убираются все... Смысла минусовать нет.
		return
	end
	
	_G.LibreAlchemy.place.count = _G.LibreAlchemy.place.count + 1
	
	-- При старте нужно показать сообщение приветствие или с возвращением
	if _G.LibreAlchemy.welcomeBack ~= nil then
		return -- Поэтому глушим дальнейший код
	end
	
	if not _G.LibreAlchemy.reactionSuccess then
		local rc, dc = _G.LibreAlchemy.fn.CountPotentialRecipes() -- Кол-во рецептов / вложенное кол-во компонентов
		
		if _G.LibreAlchemy.debug then
			common.LogInfo( "", string.format( _G.LibreAlchemy.locales.DEBUG_COUNT_RECIPES, rc ) )
			common.LogInfo( "", string.format( _G.LibreAlchemy.locales.DEBUG_COUNT_COMPONENTS, dc ) )
			common.LogInfo( "", string.format( _G.LibreAlchemy.locales.DEBUG_ITERATION_COMPONENTS, _G.LibreAlchemy.place.count ) )
		end
		
		if rc > 0 and _G.LibreAlchemy.place.count == dc then
			_G.LibreAlchemy.fn.wSetText( string.format( _G.LibreAlchemy.locales.COUNT_RECIPLES, rc ) )
		elseif _G.LibreAlchemy.place.count == dc then
			-- Изредка CountPotentialRecipes даёт 0 рецептов, когда они имеются...
			-- КОСТЫЛЬ. Добавили params.slot > 0
			-- Решили проблему с ложным срабатыванием, но другая проблема - если единственный компонент будет присутствовать в 1(0 в системе) лоте
			-- Логически не решаемо... Нужна функция avatar.IsAlchemyComponentsReady(), которая убита AS-XKJ-489-73348 10 июн. 2026г.
			-- Был убран params.slot > 0
			_G.LibreAlchemy.fn.wSetText( _G.LibreAlchemy.locales.COMPONENTS_NOT_READY )
		end
		if _G.LibreAlchemy.debug then common.LogInfo( "", "------------------------------------------------------" ) end
	end
end

--- @function _G.LibreAlchemy.events.EVENT_ALCHEMY_CANCELED
--- @description Обработчик события прерывания или завершения алхимического действия. 
--- Отвечает за скрытие интерфейса и полный сброс внутренних флагов состояния аддона в исходное положение, 
--- если процесс варки был прерван.
--- @param params table Параметры события.
--- @param params.isSuccess boolean Флаг успешности завершения действия:
--- false: Действие было прервано (например, окно алхимии закрыто).
--- true: Действие завершилось штатно.
_G.LibreAlchemy.events.EVENT_ALCHEMY_CANCELED = function( params )
    if _G.LibreAlchemy.debug then 
		common.LogInfo( "", "EVENT_ALCHEMY_CANCELED" )
		common.LogInfo( "", "isSuccess: " .. tostring( params.isSuccess ) )
	end
	
    if not params.isSuccess then
        
        -- Скрываем текстовый виджет подсказок
		_G.mainForm:Show( false )
        
        -- Сбрасываем состояние размещения компонентов в слоты
        _G.LibreAlchemy.place.placed = nil
        _G.LibreAlchemy.place.readyNotFoundMessage = false
        
        -- Сбрасываем флаги активности и успешности реакции
        _G.LibreAlchemy.reactionSuccess = false
        _G.LibreAlchemy.active = false
        
        -- Устанавливаем флаг для показа сообщения "С возвращением!" при следующем открытии алхимии
        _G.LibreAlchemy.welcomeBack = true
    end
end

--- @function EVENT_ALCHEMY_STARTED
--- @description Умение алхимии начало действие после использования алхимического инструмента.
_G.LibreAlchemy.events.EVENT_ALCHEMY_STARTED = function()
    if _G.LibreAlchemy.debug then common.LogInfo( "", "EVENT_ALCHEMY_STARTED" ) end
	
	_G.mainForm:Show( true )
	_G.LibreAlchemy.active = true
	
	-- ОБЯЗАТЕЛЬНО актуализируем количество барабанов.
    _G.LibreAlchemy.nDrums = avatar.GetAlchemyInfo().drumsCount
	
	if _G.LibreAlchemy.welcomeBack then
		_G.LibreAlchemy.fn.wSetText( _G.LibreAlchemy.locales.WELCOME_BACK )
	elseif _G.LibreAlchemy.welcomeBack == false then
		_G.LibreAlchemy.fn.wSetText( _G.LibreAlchemy.locales.GREETINGS )
    end
end

--- @function EVENT_AVATAR_CREATED
--- @description Срабатывает при инициализации аватара (ЗАГРУЗКА ПЕРСОНАЖА В МИР).
--- @param params table - Параметры события.
--- @param params.id ObjectId - Идентификатор аватара (not nil).
_G.LibreAlchemy.events.EVENT_AVATAR_CREATED = function( params )
	-- Инициализируем локализацию
	_G.LibreAlchemy.fn.InitLocale()
	
	-- Инициализируем настройки виджетов
	_G.LibreAlchemy.fn.InitWidgets()
end