-- AlchemyRecipeService.lua
-- Кэш рецептов, фильтрация, подсчёт возможных рецептов.

Class( "AlchemyRecipeService", {
    _state = nil,
})

function AlchemyRecipeService:Init( state )
    self._state = state
end

-- Кэширует список рецептов
function AlchemyRecipeService:BuildRecipeCache()
    if self._state.recipeCache ~= nil then return end

    self._state.recipeCache = {}
    local ainf = avatar.GetAlchemyInfo()

    for ir, vr in pairs( ainf.recipes ) do
        local gr = avatar.GetRecipeInfo( vr )
        local recipe = {
            cc = 0,
            wName = gr.name,
            name = userMods.FromWString( gr.name ),
            score = gr.score,
            cli = {},
        }

        for _, vc in pairs( gr.components ) do
            local co = avatar.GetComponentInfo( vc )
            local cn = userMods.FromWString( co.name )
            recipe.cli[cn] = ( recipe.cli[cn] or 0 ) + 1
            recipe.cc = recipe.cc + 1
        end

        self._state.recipeCache[ir] = recipe
    end
end

-- Фильтрует рецепты по компонентам
function AlchemyRecipeService:FilterByComponents( availableComponents, filledDrums )
    self:BuildRecipeCache()
    self._state.filteredRecipes = {}
    local count = 0

    for _, recipe in pairs( self._state.recipeCache ) do
        if recipe.cc <= filledDrums then
            local canCraft = true
            for compName, needed in pairs( recipe.cli ) do
                if ( availableComponents[compName] or 0 ) < needed then
                    canCraft = false
                    break
                end
            end
            if canCraft then
                table.insert( self._state.filteredRecipes, recipe )
                count = count + 1
            end
        end
    end

    return count
end

-- Подсчёт возможных рецептов
function AlchemyRecipeService:CountPotential()
    self:BuildRecipeCache()
    local potentialCount = 0
    local filledDrums = 0
    local available = {}

    for drumIdx = 1, self._state.drumsCount do
        local drumInfo = avatar.GetAlchemyDrumInfo( drumIdx - 1 )
        if drumInfo and drumInfo.itemId ~= nil then
            filledDrums = filledDrums + 1
            local seen = {}
            if drumInfo.components then
                for _, compId in pairs( drumInfo.components ) do
                    local ci = avatar.GetComponentInfo( compId )
                    if ci then
                        seen[userMods.FromWString( ci.name )] = 1
                    end
                end
            end
            for name, _ in pairs( seen ) do
                available[name] = ( available[name] or 0 ) + 1
            end
        end
    end

    for _, recipe in pairs( self._state.recipeCache ) do
        if recipe.cc <= filledDrums then
            local ok = true
            for cn, needed in pairs( recipe.cli ) do
                if ( available[cn] or 0 ) < needed then ok = false; break end
            end
            if ok then potentialCount = potentialCount + 1 end
        end
    end

    return potentialCount, filledDrums
end