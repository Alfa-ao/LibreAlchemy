-- AlchemyRecipeService.lua
-- Кэш рецептов, фильтрация, подсчёт возможных рецептов.

Class( "AlchemyRecipeService", {
    _state = nil,
})

function AlchemyRecipeService:Init( state )
    self._state = state
end

-- Кеширует весь список существующих зелий в алхимии. 
-- Кол-во ( компонентов в одном зелье / повторений одинаковых компонентов ).
--- avatar.GetAlchemyInfo():
--- recipes - Возвращает таблицу обо всех рецептов существующих в алхимии (249 зелий на сегодняшний день)
function AlchemyRecipeService:BuildRecipeCache() -- (ПЕРЕДЕЛАТЬ) BuildRecipeCache на CreateRecipeCache
    if self._state.recipeCache ~= nil then return end

    self._state.recipeCache = {}
    local alchemyInfo = avatar.GetAlchemyInfo()
    self._state.drumsCount = alchemyInfo.drumsCount
	--[[ log( alchemyInfo )
	["var_dump"] => table(1) {
		[1] => table(0) {
		["active"] => boolean(true) - true, если (Открыт инструмент алхимии)
		["correctionCount"] => number(4)
		["defaultResultCount"] => number(1)
		["drumSize"] => number(24)
		["drumsCount"] => number(5)
		["finished"] => boolean(false)
		["id"] => userdata(userdata: 0x57d46ce0)
		["perComponentBonus"] => number(0)
		["perfectBonus"] => number(0)
		["reactionInited"] => boolean(false)
		["recipes"] => table(248) {
			[0] => userdata(userdata: 0x57d46d68)
			[1] => userdata(userdata: 0x57d46da8)
			...
			[248] => userdata(userdata: 0x57d4b570)
		}
		["unusedRollsBonus"] => number(0.5)
		}
	} ]]
	
	

    for ir, vr in pairs( alchemyInfo.recipes ) do -- (ПЕРЕДЕЛАТЬ) vr на recipe, ir на tableId
        local recipeInfo = avatar.GetRecipeInfo( vr )
		--[[ log(recipeInfo)
		["var_dump"] => table(1) {
			[1] => table(0) {
				["bindResult"] => boolean(false) -- будет ли результат привязан к аватару
				
				-- table of ObjectId or ResourceId - массив компонент рецепта. Кол-во требуемых компонентов
				-- avatar.GetComponentInfo( components ).name
				-- примерно:
				["components"] => table(3) { 
					[0] => userdata(userdata: 0x60ff7380) -- { name = WString( Ослепление ) }
					[1] => userdata(userdata: 0x60ff73c0) -- { name = WString( Биоморфичность ) }
					[2] => userdata(userdata: 0x60ff7400) -- { name = WString( Исцеление ) }
					[3] => userdata(userdata: 0x60ff7440) -- { name = WString( Исцеление ) }
				}
				
				
				["defaultItem"] => number(7736) -- ObjectId or nil - идентификатор предмета, получаемый из рецепта по умолчанию
				["description"] => userdata(userdata: 0x60ff71f0) -- ValuedText or nil - описание с подставленными текущими значениями параметров
				["id"] => userdata(userdata: 0x60ff70f8) -- RecipeId - Id ресурса рецепта
				["image"] => userdata(userdata: 0x60ff7230)
				["name"] => userdata(userdata: 0x60ff7138) -- WString( Имя зелья )
				["nextRecipePoints"] => number(0) -- UnlockId or nil - идентификатор анлока следующего ресурса (если ещё не выполнен)
				["resultItems"] => table(0) { -- table of ObjectId - индексированный с 0 массив идентификаторов предметов, создаваемых по рецепту (отсортированы по качеству от менее качественного (0) до более качественного)
					[0] => number(7736)
				}
				["resultQuantity"] => number(1) -- количество предметов, получаемых из рецепта по умолчанию
				["score"] => number(33) -- необходимый уровень (score) умения для изучения
				
				-- SkillId:GetInfo()
					-- name: WString - локализованное название скилла
					-- description: WString - локализованное описание скилла
					-- sysName: string or nil - системное название скилла
					-- image: TextureId - идентификатор текстуры для иконки умения
					-- type: number (enum CRAFTING_SKILL_...) - тип скилла (какие компоненты входят в рецепт, какого типа игра и т.п.)
					-- useLevels: boolean - true, если скилл прокачивается ступенчатыми уровнями, иначе плавно от 1 до максимального уровня
				
				-- CRAFTING_SKILL_UNKNOWN - неизвестный тип.
				-- CRAFTING_SKILL_ALCHEMY - по типу алхимии. Компоненты крафта - алхимические компоненты предмета.
				-- CRAFTING_SKILL_DICE_CRAFT - новый ARMOR_CRAFT с карточной игрой. Компоненты - обычные предметы.
				["skillId"] => userdata(userdata: 0x60ff7188) -- SkillId or nil - идентификатор ресурса скила, которому принадлежит рецепт (если скилл выучен игроком)
			}
		} ]]
		
        local recipe = {
            cc = 0, -- Кол-во компонентов
            wName = recipeInfo.name, -- WString( имя зелья ) -- смысл в нём ? (УДАЛИТЬ)
            name = userMods.FromWString( recipeInfo.name ), -- имя зелья
            score = recipeInfo.score, -- лвл
            cli = { -- (ПЕРЕДЕЛАТЬ) cli на uniqueComponentsCount
				-- имя компонента = кол-во одинаковых компонентов.
					-- Ослепление = 2, Исцеление = 1
			},
        }

        for _, vc in pairs( recipeInfo.components ) do -- (ПЕРЕДЕЛАТЬ) vc на component
			
			-- возвращаемые значения
			-- nil, если компонент не найден по идентификатору, или table:
				-- id: ComponentPropertyId - Id ресурса компонента
				-- name: WString - название
				-- description: WString - описание
            local co = avatar.GetComponentInfo( vc ) -- (ПЕРЕДЕЛАТЬ) co на componentInfo
			
            local cn = userMods.FromWString( co.name ) -- (ПЕРЕДЕЛАТЬ) cn на componentName
			
            recipe.cli[cn] = ( recipe.cli[cn] or 0 ) + 1 -- имя компонента = кол-во одинаковых компонентов.
            recipe.cc = recipe.cc + 1 -- (ПЕРЕДЕЛАТЬ) cc на componentsCount
        end

        self._state.recipeCache[ir] = recipe
		--[[
		{
			{ componentsCount, name, score, uniqueComponentsCount },
			...
		}
		]]
    end
end

-- Фильтрует рецепты по компонентам
function AlchemyRecipeService:FilterByComponents( availableComponents, filledDrums )
    self:BuildRecipeCache()
    self._state.filteredRecipes = {}
    local count = 0

    for _, recipe in pairs( self._state.recipeCache ) do
        if recipe.cc <= filledDrums then -- Интересно, стоит ли делать требуемое кол-во компонентов, т.е. ==
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
    self:BuildRecipeCache() -- Оставить
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