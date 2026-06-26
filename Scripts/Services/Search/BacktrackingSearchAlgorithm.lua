-- Search/BacktrackingSearchAlgorithm.lua

Class( "BacktrackingSearchAlgorithm", SearchAlgorithm() )

function BacktrackingSearchAlgorithm:Execute( state, totalCorrections, linesAvailability )
	local foundResults = {}
	local foundSet = {}
	
	-- Локальная рекурсивная функция
	local function recursiveSearch( drumIdx, shiftsLeft, currentShifts, lineZero, lineMinusOne, linePlusOne )
		local filteredRecipes = state.filteredRecipes
		
		-- Если мы уже нашли все возможные отфильтрованные рецепты, дальше искать нет смысла
		if filteredRecipes and #filteredRecipes > 0 and #foundResults >= #filteredRecipes then 
			return 
		end
		
		-- Базовый случай рекурсии или переход к следующему барабану
		if drumIdx > 0 then
			-- Если для текущего барабана нет возможных сдвигов (он пустой или не инициализирован)
			if next( state.drumShiftMap[ drumIdx ] ) == nil then
				currentShifts[ drumIdx ] = 0 -- Фиксируем сдвиг 0
				-- Идем к следующему (предыдущему по индексу) барабану
				recursiveSearch( drumIdx - 1, shiftsLeft, currentShifts, lineZero, lineMinusOne, linePlusOne )
				currentShifts[ drumIdx ] = nil -- Откатываем состояние
				return
			end
			
			-- Вычисляем максимальный сдвиг для текущего барабана (ограничен оставшимися очками и глобальным лимитом)
			local maxShift = math.min( shiftsLeft, state.maxCorrections )
			
			-- Перебираем все возможные сдвиги для текущего барабана
			for shift = -maxShift, maxShift do 
				local nextLeft = shiftsLeft - math.abs( shift ) -- number (int). Очки коррекции, которые останутся для следующих барабанов.
				
				-- Переменные для отслеживания того, что мы добавили в линии (нужны для отката состояния)
				local addedZero, addedMinus, addedPlus = nil, nil, nil 
				
				-- Обработка линии 0 (текущая позиция)
				if lineZero then
					local comp = state.drumShiftMap[ drumIdx ][ shift ] -- Имя компонента при сдвиге `shift`
					if comp then
						lineZero[ comp ] = ( lineZero[ comp ] or 0 ) + 1 -- Увеличиваем счетчик компонента в линии
						addedZero = comp
					end
				end
				
				-- Обработка линии -1 (сдвиг на 1 влево от текущего)
				if lineMinusOne then
					local comp = state.drumShiftMap[ drumIdx ][ shift - 1 ] -- Имя компонента при сдвиге `shift - 1`
					if comp then
						lineMinusOne[ comp ] = ( lineMinusOne[ comp ] or 0 ) + 1
						addedMinus = comp
					end
				end
				
				-- Обработка линии +1 (сдвиг на 1 вправо от текущего)
				if linePlusOne then
					local comp = state.drumShiftMap[ drumIdx ][ shift + 1 ] -- Имя компонента при сдвиге `shift + 1`
					if comp then
						linePlusOne[ comp ] = ( linePlusOne[ comp ] or 0 ) + 1
						addedPlus = comp
					end
				end

				-- Если хотя бы в одну линию что-то добавилось, имеет смысл идти глубже (рекурсия)
				if addedZero or addedMinus or addedPlus then
					currentShifts[ drumIdx ] = shift -- Фиксируем текущий сдвиг для этого барабана
					
					-- Рекурсивный вызов для следующего барабана
					recursiveSearch( drumIdx - 1, nextLeft, currentShifts, lineZero, lineMinusOne, linePlusOne )
					
					-- Backtracking
					currentShifts[ drumIdx ] = nil -- Откат состояния
					
					-- Уменьшаем счетчики компонентов в линиях, которые мы увеличили перед рекурсией
					if addedZero then
						lineZero[ addedZero ] = lineZero[ addedZero ] - 1
						if lineZero[ addedZero ] == 0 then lineZero[ addedZero ] = nil end -- Чистим ключ, если счетчик обнулился
					end
					if addedMinus then
						lineMinusOne[ addedMinus ] = lineMinusOne[ addedMinus ] - 1
						if lineMinusOne[ addedMinus ] == 0 then lineMinusOne[ addedMinus ] = nil end
					end
					if addedPlus then
						linePlusOne[ addedPlus ] = linePlusOne[ addedPlus ] - 1
						if linePlusOne[ addedPlus ] == 0 then linePlusOne[ addedPlus ] = nil end
					end
				end
			end
		else
			local function registerLine( componentMap )
				if not componentMap then return end
				local bestRecipe = self._evaluator:FindBestRecipe( componentMap, filteredRecipes )
				if bestRecipe and not foundSet[ bestRecipe.name ] then
					foundSet[ bestRecipe.name ] = true
					table.insert( foundResults, {
						recipe     = bestRecipe,
						shifts     = self._mathUtils:ShallowCopy( currentShifts ),
						components = self._mathUtils:ShallowCopy( componentMap ),
					} )
				end
			end
			
			-- Мы прошли все барабаны. Теперь регистрируем накопленные компоненты как потенциальные результаты для каждой линии.
			registerLine( lineZero )
			registerLine( lineMinusOne )
			registerLine( linePlusOne )
		end
	end

	-- Запуск перебора
	for shiftsLeft = 0, totalCorrections do
		recursiveSearch(
			state.drumsCount, 
			shiftsLeft, 
			{}, 
			linesAvailability.zero, 
			linesAvailability.minusOne, 
			linesAvailability.plusOne
		)
	end

	return foundResults
end