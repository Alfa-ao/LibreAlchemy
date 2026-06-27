-- Services/AlchemySearchService.lua

Class( "AlchemySearchService", {
	_state         = nil,
	_recipeService = nil,
	_mathUtils     = nil,
	_mapper        = nil,
	_evaluator     = nil,
	_algorithm     = nil,
} )

function AlchemySearchService:Init( state, recipeService, mapper, algorithm )
	self._state         = state
	self._recipeService = recipeService
	self._mapper        = mapper
	self._foundSet      = {}
	
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

-- Главная точка входа.
function AlchemySearchService:FindBestRecipes()
	local alchemyInfo = avatar.GetAlchemyInfo()
	
	-- Обновляем максимальную коррекцию (СЛОМАНО - maxCorrectionsPerColumn всегда (-1))
	local firstDrumInfo = avatar.GetAlchemyDrumInfo( 0 )
	if firstDrumInfo and firstDrumInfo.maxCorrectionsPerColumn and firstDrumInfo.maxCorrectionsPerColumn > 0 then
		self._state.maxCorrections = firstDrumInfo.maxCorrectionsPerColumn
	end

	local totalCorrections = alchemyInfo.correctionCount or 0
	self._state.drumsCount = alchemyInfo.drumsCount or self._state.drumsCount

	-- Определяем доступность линий
	local linesAvailability = {
		minusOne = avatar.IsAlchemyLineAvailable( -1 ) and {} or nil,
		zero     = {},
		plusOne  = avatar.IsAlchemyLineAvailable( 1 ) and {} or nil,
	}

	-- Строим карту сдвигов
	local drumRequiredComponents, totalDrumsCount = self._mapper:BuildMap()

	-- Фильтруем рецепты
	self._recipeService:FilterByComponents( drumRequiredComponents, totalDrumsCount )

	-- Алгоритм поиска
	self._state.foundResults = self._algorithm:Execute( 
		self._state, 
		totalCorrections, 
		linesAvailability 
	)

	return self._state.foundResults
end