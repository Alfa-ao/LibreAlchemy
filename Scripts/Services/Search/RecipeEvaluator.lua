-- Services/Search/RecipeEvaluator.lua

Class( "RecipeEvaluator", {} )

-- Ищет лучший рецепт для накопленных компонентов.
-- Возвращает таблицу рецепта или nil.
function RecipeEvaluator:FindBestRecipe( componentMap, filteredRecipes ) --- ?table
	if not filteredRecipes then return nil end
	
	local bestRecipe = nil
	local bestScore = -1

	for _, recipe in pairs( filteredRecipes ) do
		local isMatch = true
		
		for componentName, requiredCount in pairs( recipe.requiredComponents ) do
			if ( componentMap[ componentName ] or 0 ) < requiredCount then
				isMatch = false
				break
			end
		end
		
		if isMatch and recipe.score > bestScore then
			bestRecipe = recipe
			bestScore = recipe.score
		end
	end

	return bestRecipe
end