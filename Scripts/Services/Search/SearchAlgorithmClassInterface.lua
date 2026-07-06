--------------------------------------------------------------------------------
-- Services/Search/SearchAlgorithmClassInterface.lua
-- Базовый интерфейс (абстрактный класс) для алгоритмов поиска.
-- Определяет контракт, который должны реализовать конкретные алгоритмы поиска.
--------------------------------------------------------------------------------

Class( "SearchAlgorithmClassInterface", {
	_evaluator = nil,  -- Экземпляр RecipeEvaluator для оценки найденных комбинаций.
	_mathUtils = nil,  -- Экземпляр MathUtils для математических операций.
} )

--------------------------------------------------------------------------------
--- Инициализация алгоритма поиска.
--- @param evaluator table RecipeEvaluator
--- @param mathUtils table MathUtils
--------------------------------------------------------------------------------
function SearchAlgorithmClassInterface:Init( evaluator, mathUtils ) --- void
	self._evaluator = evaluator
	self._mathUtils = mathUtils
end

--------------------------------------------------------------------------------
--- Контракт метода выполнения поиска.
--- Должен быть переопределен в классах-наследниках.
--- @param ... any
--- @return table
--------------------------------------------------------------------------------
function SearchAlgorithmClassInterface:Execute( ... )
	error( "SearchAlgorithmClassInterface:Execute must be implemented by subclass" )
end