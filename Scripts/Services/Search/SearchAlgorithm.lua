-- SearchAlgorithm.lua

Class( "SearchAlgorithm", {
	_evaluator = nil,
	_mathUtils = nil,
} )

function SearchAlgorithm:Init( evaluator, mathUtils )
	self._evaluator = evaluator
	self._mathUtils = mathUtils
end

-- Контракт метода (Abstract method). Должен быть переопределен в наследниках.
function SearchAlgorithm:Execute( drumShiftMap, filteredRecipes, maxCorrections, totalCorrections, linesAvailability )
	error( "SearchAlgorithm:Execute must be implemented by subclass" )
end