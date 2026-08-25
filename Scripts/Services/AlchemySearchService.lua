--------------------------------------------------------------------------------
-- Scripts/Services/AlchemySearchService.lua
-- Сервис для поиска оптимальных рецептов алхимии.
--------------------------------------------------------------------------------

Class( "AlchemySearchService", {
	_state     = nil, -- Ссылка на глобальное состояние аддона (AlchemyState).
	_recipe    = nil, -- Сервис для работы с рецептами (кэширование и фильтрация).
	_mapper    = nil, -- Маппер сдвигов барабанов (DrumShiftMapper).
	_algorithm = nil, -- Алгоритм поиска (реализация BacktrackingSearchAlgorithm).
	_foundSet  = nil, -- Хеш-таблица для отслеживания уникальных найденных рецептов (используется внутри алгоритма).
} )

--------------------------------------------------------------------------------
--- Инициализация сервиса поиска.
--- Проверяет, что переданный алгоритм реализует требуемый интерфейс.
--- @param state table AlchemyState
--- @param recipeService table AlchemyRecipeService
--- @param mapper table DrumShiftMapper
--- @param algorithm table BacktrackingSearchAlgorithm
--------------------------------------------------------------------------------
function AlchemySearchService:Init( state, recipeService, mapper, algorithm ) --- void
	self._state      = state
	self._recipe     = recipeService
	self._mapper     = mapper
	self._foundSet   = {}
	self._algorithm  = algorithm
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
	self._recipe:FilterByComponents( drumRequiredComponents, totalDrumsCount )

	-- Запускает алгоритм поиска для перебора вариантов с учетом коррекций и доступных линий
	self._state.foundResults = self._algorithm:Execute( 
		self._state, 
		totalCorrections, 
		linesAvailability 
	)
	
--[[
table(4) {
    [1] => table(0) {
        ["components"] => table(0) {
            [Аспект победителя] => number(1)
            [Астральность] => number(1)
            [Биоморфичность] => number(1)
            [Исцеление] => number(1)
            [Царственность] => number(1)
        }
        ["recipe"] => table(0) {
            ["componentsCount"] => number(5)
            ["name"] => WString(32) "Королевское зелье восстановления"
            ["requiredComponents"] => table(0) {
                [Аспект победителя] => number(1)
                [Астральность] => number(1)
                [Биоморфичность] => number(1)
                [Исцеление] => number(1)
                [Царственность] => number(1)
            }
            ["score"] => number(120)
        }
        ["shifts"] => table(5) {
            [1] => number(-0)
            [2] => number(-1)
            [3] => number(0)
            [4] => number(-1)
            [5] => number(0)
        }
    }
    [2] => table(0) {
        ["components"] => table(0) {
            [Аспект победителя] => number(1)
            [Биоморфичность] => number(1)
            [Исцеление] => number(1)
            [Призрачность] => number(1)
            [Технологичность] => number(1)
        }
        ["recipe"] => table(0) {
            ["componentsCount"] => number(5)
            ["name"] => WString(36) "Кибернетическое зелье восстановления"
            ["requiredComponents"] => table(0) {
                [Аспект победителя] => number(1)
                [Биоморфичность] => number(1)
                [Исцеление] => number(1)
                [Призрачность] => number(1)
                [Технологичность] => number(1)
            }
            ["score"] => number(115)
        }
        ["shifts"] => table(5) {
            [1] => number(-0)
            [2] => number(-1)
            [3] => number(1)
            [4] => number(0)
            [5] => number(0)
        }
    }
    [3] => table(0) {
        ["components"] => table(0) {
            [Аспект телохранителя] => number(1)
            [Биоморфичность] => number(1)
            [Исцеление] => number(1)
            [Призрачность] => number(1)
            [Технологичность] => number(1)
        }
        ["recipe"] => table(0) {
            ["componentsCount"] => number(5)
            ["name"] => WString(31) "Кибернетическое зелье исцеления"
            ["requiredComponents"] => table(0) {
                [Аспект телохранителя] => number(1)
                [Биоморфичность] => number(1)
                [Исцеление] => number(1)
                [Призрачность] => number(1)
                [Технологичность] => number(1)
            }
            ["score"] => number(115)
        }
        ["shifts"] => table(5) {
            [1] => number(3)
            [2] => number(-1)
            [3] => number(0)
            [4] => number(0)
            [5] => number(0)
        }
    }
    [4] => table(0) {
        ["components"] => table(0) {
            [Аспект телохранителя] => number(1)
            [Астральность] => number(1)
            [Биоморфичность] => number(1)
            [Исцеление] => number(1)
            [Царственность] => number(1)
        }
        ["recipe"] => table(0) {
            ["componentsCount"] => number(5)
            ["name"] => WString(27) "Королевское зелье исцеления"
            ["requiredComponents"] => table(0) {
                [Аспект телохранителя] => number(1)
                [Астральность] => number(1)
                [Биоморфичность] => number(1)
                [Исцеление] => number(1)
                [Царственность] => number(1)
            }
            ["score"] => number(120)
        }
        ["shifts"] => table(5) {
            [1] => number(3)
            [2] => number(0)
            [3] => number(0)
            [4] => number(0)
            [5] => number(1)
        }
    }
}
]]
	return self._state.foundResults
end