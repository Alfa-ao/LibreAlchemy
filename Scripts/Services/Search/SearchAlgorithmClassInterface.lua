-- Services/Search/SearchAlgorithmClassInterface.lua

Class( "SearchAlgorithmClassInterface", {
	_evaluator = nil,
	_mathUtils = nil,
} )

function SearchAlgorithmClassInterface:Init( evaluator, mathUtils ) --- void
	self._evaluator = evaluator
	self._mathUtils = mathUtils
end

-- Контракт метода. Должен быть переопределен в наследниках.
function SearchAlgorithmClassInterface:Execute( ... ) --- table
	error( "SearchAlgorithm:Execute must be implemented by subclass" )
end