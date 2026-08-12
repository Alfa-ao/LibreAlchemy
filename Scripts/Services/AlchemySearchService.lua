--------------------------------------------------------------------------------
-- Scripts/Services/AlchemySearchService.lua
-- Сервис для поиска оптимальных рецептов алхимии.
--------------------------------------------------------------------------------

Class( "AlchemySearchService", {
	_state         = nil, -- Ссылка на глобальное состояние аддона (AlchemyState).
	_recipeService = nil, -- Сервис для работы с рецептами (кэширование и фильтрация).
	_mapper        = nil, -- Маппер сдвигов барабанов (DrumShiftMapper).
	_algorithm     = nil, -- Алгоритм поиска (реализация SearchAlgorithmClassInterface).
	_foundSet      = nil, -- Хеш-таблица для отслеживания уникальных найденных рецептов (используется внутри алгоритма).
} )

--------------------------------------------------------------------------------
--- Инициализация сервиса поиска.
--- Проверяет, что переданный алгоритм реализует требуемый интерфейс.
--- @param state table AlchemyState
--- @param recipeService table AlchemyRecipeService
--- @param mapper table DrumShiftMapper
--- @param algorithm table SearchAlgorithmClassInterface
--------------------------------------------------------------------------------
function AlchemySearchService:Init( state, recipeService, mapper, algorithm ) --- void
	self._state         = state
	self._recipeService = recipeService
	self._mapper        = mapper
	self._foundSet      = {}
	
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
--- Главная точка входа для поиска лучших рецептов.
--- Собирает данные, строит карту сдвигов, фильтрует рецепты
--- и запускает алгоритм поиска для нахождения оптимальных комбинаций.
--- @return table -- найдено список рецептов
--------------------------------------------------------------------------------
function AlchemySearchService:FindBestRecipes()
	local alchemyInfo = avatar.GetAlchemyInfo()
	
	-- Обновляет максимальную коррекцию (сдвиг) на основе данных первого барабана
	local firstDrumInfo = avatar.GetAlchemyDrumInfo( 0 )
	
	if firstDrumInfo and firstDrumInfo.maxCorrectionsPerColumn and firstDrumInfo.maxCorrectionsPerColumn > 0 then
		self._state.maxCorrections = firstDrumInfo.maxCorrectionsPerColumn
	end

	local totalCorrections = alchemyInfo.correctionCount or 0
	self._state.drumsCount = alchemyInfo.drumsCount or self._state.drumsCount

	-- Определяет доступность линий алхимии (сдвиги -1, 0, +1)
	local linesAvailability = {
		minusOne = avatar.IsAlchemyLineAvailable( -1 ) and {} or nil,
		zero     = {},
		plusOne  = avatar.IsAlchemyLineAvailable( 1 ) and {} or nil,
	}

	-- Строит карту сдвигов для каждого барабана
	local drumRequiredComponents, totalDrumsCount = self._mapper:BuildMap()

	-- Фильтрует глобальный кэш рецептов, оставляя только подходящие по компонентам
	self._recipeService:FilterByComponents( drumRequiredComponents, totalDrumsCount )

	-- Запускает алгоритм поиска для перебора вариантов с учетом коррекций и доступных линий
	self._state.foundResults = self._algorithm:Execute( 
		self._state, 
		totalCorrections, 
		linesAvailability 
	)
	
	--[[
	{
		{
			"components" => { "Ослепление" => 2 },
			"recipe" => { 
				"componentsCount" => 2, 
				"name" => "Обычный пятновыводитель",
				"requiredComponents" => { "Ослепление" => 2 },
				"score" => 1
			},
			"shifts" => { 0, 0, 0, 0, 0 }
		},
		...
	}
	]]
	return self._state.foundResults
end