-- AlchemyState.lua
-- Хранилище изменяемого состояния аддона.

Class( "AlchemyState", {
    active = false,
    reactionSuccess = false,
    messageType = 0,       -- См. в AlchemyConfig.

    -- Кэш данных
    recipeCache = nil,     -- Кэш списка всех доступных рецептов алхимии.
    filteredRecipes = nil, -- Отфильтрованный список рецептов.
    drumShiftMap = nil,    -- Карта сдвигов: хранит компоненты в барабанах с учетом возможных сдвигов (индекс [барабан][сдвиг] = имя компонента).
    foundResults = nil,    -- Таблица найденных вариантов (рецепт + сдвиги барабанов).
	
    place = {
        placed = nil,
        readyNotFoundMessage = false,
        count = 0,
    },
})

function AlchemyState:ResetPlace()
    self.place.placed = nil
    self.place.readyNotFoundMessage = false
    self.place.count = 0
end

function AlchemyState:ResetSearchCache()
    self.filteredRecipes = nil
    self.drumShiftMap = nil
    self.foundResults = nil
end

function AlchemyState:ResetRecipeCache()
    self.recipeCache = nil
end