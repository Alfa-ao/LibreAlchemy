--------------------------------------------------------------------------------
-- Scripts/Services/AlchemySearchService.lua
-- Сервис для поиска оптимальных рецептов алхимии.
-- Координирует работу маппера сдвигов, фильтрации рецептов и алгоритма поиска,
-- предоставляя единую точку входа для получения лучших комбинаций компонентов.
--------------------------------------------------------------------------------

Class( "AlchemySearchService", {
	_state         = nil, -- Ссылка на глобальное состояние аддона (AlchemyState).
	_recipeService = nil, -- Сервис для работы с рецептами (кэширование и фильтрация).
	_mathUtils     = nil, -- Утилиты для математических операций.
	_mapper        = nil, -- Маппер сдвигов барабанов (DrumShiftMapper).
	_evaluator     = nil, -- Оценщик рецептов (RecipeEvaluator).
	_algorithm     = nil, -- Алгоритм поиска (реализация SearchAlgorithmClassInterface).
} )

--------------------------------------------------------------------------------
-- Инициализация сервиса поиска.
-- Проверяет, что переданный алгоритм реализует требуемый интерфейс.
--------------------------------------------------------------------------------
function AlchemySearchService:Init( state, recipeService, mapper, algorithm ) --- void
	self._state         = state
	self._recipeService = recipeService
	self._mapper        = mapper
	self._foundSet      = {} -- Хеш-таблица для отслеживания уникальных найденных рецептов (используется внутри алгоритма).
	
	-- Проверка реализации интерфейса алгоритма поиска
	if InstanceOf( algorithm, _G.SearchAlgorithmClassInterface ) then
		self._algorithm = algorithm
	else
		local objectClass = GetParentClass( algorithm )
		local className = GetClassName( objectClass )
		
		error( string.format( 
			"Unsupported class '%s' does not have an interface 'SearchAlgorithmClassInterface'", 
			className 
		) )
	end
end

--------------------------------------------------------------------------------
-- Главная точка входа для поиска лучших рецептов.
-- Собирает актуальные данные из API, строит карту сдвигов, фильтрует рецепты
-- и запускает алгоритм поиска для нахождения оптимальных комбинаций.
--------------------------------------------------------------------------------
function AlchemySearchService:FindBestRecipes() --- table
	local alchemyInfo = avatar.GetAlchemyInfo()
	
	-- Обновляем максимальную коррекцию (сдвиг) на основе данных первого барабана
	local firstDrumInfo = avatar.GetAlchemyDrumInfo( 0 )
	
	if firstDrumInfo and firstDrumInfo.maxCorrectionsPerColumn and firstDrumInfo.maxCorrectionsPerColumn > 0 then
		self._state.maxCorrections = firstDrumInfo.maxCorrectionsPerColumn
	end

	local totalCorrections = alchemyInfo.correctionCount or 0
	self._state.drumsCount = alchemyInfo.drumsCount or self._state.drumsCount

	-- Определяем доступность линий алхимии (сдвиги -1, 0, +1)
	local linesAvailability = {
		minusOne = avatar.IsAlchemyLineAvailable( -1 ) and {} or nil,
		zero     = {},
		plusOne  = avatar.IsAlchemyLineAvailable( 1 ) and {} or nil,
	}

	-- Строим карту возможных сдвигов для каждого барабана
	local drumRequiredComponents, totalDrumsCount = self._mapper:BuildMap()

	-- Фильтруем глобальный кэш рецептов, оставляя только подходящие по базовым компонентам
	self._recipeService:FilterByComponents( drumRequiredComponents, totalDrumsCount )

	-- Запускаем алгоритм поиска для перебора вариантов с учетом коррекций и доступных линий
	self._state.foundResults = self._algorithm:Execute( 
		self._state, 
		totalCorrections, 
		linesAvailability 
	)

	return self._state.foundResults
end