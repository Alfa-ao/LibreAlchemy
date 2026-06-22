-- AlchemySearchService.lua
-- Карта сдвигов барабанов, рекурсивный поиск комбинаций.

Class( "AlchemySearchService", {
    _state = nil,
    _recipeService = nil,
})

function AlchemySearchService:Init( state, recipeService )
    self._state = state
    self._recipeService = recipeService
end

function AlchemySearchService:CopyTable( tbl )
    if type( tbl ) ~= "table" then return nil end
    local copy = {}
    for k, v in pairs( tbl ) do copy[k] = v end
    return copy
end

-- Строит карту сдвигов барабанов
function AlchemySearchService:BuildDrumShiftMap()
    local drc = {}
    self._state.drumShiftMap = {}
    local tdc = 0

    for dru = 1, self._state.drumsCount do
        self._state.drumShiftMap[dru] = {}
        local dri = avatar.GetAlchemyDrumInfo( dru - 1 )

        if dri.components ~= nil and type( dri.components ) == "table" then
            tdc = tdc + 1
            local d1c = {}
            local compCount = #dri.components
            if compCount == 0 and dri.components[1] ~= nil then compCount = 1 end

            for sh = -self._state.maxCorrections, self._state.maxCorrections do
                local cp = ( dri.position or 0 ) + sh
                if cp < 0 then cp = cp + compCount
                elseif cp >= compCount then cp = cp - compCount end

                local ti = cp
                if dri.components[ti] == nil and dri.components[ti + 1] ~= nil then
                    ti = ti + 1
                end

                if dri.components[ti] ~= nil then
                    local gc = avatar.GetComponentInfo( dri.components[ti] )
                    if gc ~= nil then
                        local cn = userMods.FromWString( gc.name )
                        self._state.drumShiftMap[dru][sh] = cn
                        d1c[cn] = 1
                    end
                end
            end

            for cn, _ in pairs( d1c ) do
                drc[cn] = ( drc[cn] or 0 ) + 1
            end
        end
    end

    return drc, tdc
end

-- Процедура поиска: BuildMap -> Filter -> RecursiveSearch
function AlchemySearchService:FindBestRecipes()
    local ainf = avatar.GetAlchemyInfo()
    local dri = avatar.GetAlchemyDrumInfo( 0 )

    self._state.maxCorrections = dri.maxCorrectionsPerColumn or self._state.maxCorrections
    local nRota = ainf.correctionCount or 0
    self._state.drumsCount = ainf.drumsCount or self._state.drumsCount

    local lineMinus1 = avatar.IsAlchemyLineAvailable( -1 ) and {} or nil
    local linePlus1  = avatar.IsAlchemyLineAvailable( 1 ) and {} or nil

    local drc, tdc = self:BuildDrumShiftMap()
    self._recipeService:FilterByComponents( drc, tdc )

    self._state.foundResults = {}

    for shiftsLeft = 0, nRota do
        self:_RecursiveSearch(
            self._state.drumsCount, shiftsLeft, {}, {}, lineMinus1, linePlus1
        )
    end

    return self._state.foundResults
end

-- Рекурсивный поиск
function AlchemySearchService:_RecursiveSearch( drumIdx, shiftsLeft, currentShifts, line0, lineMinus1, linePlus1 )
    local filt = self._state.filteredRecipes
    local found = self._state.foundResults
    if filt and #filt > 0 and #found >= #filt then return end

    if drumIdx > 0 then
        if self._state.drumShiftMap[drumIdx][0] == nil then
            if drumIdx > 1 or ( drumIdx == 1 and shiftsLeft == 0 ) then
                currentShifts[drumIdx] = 0
                self:_RecursiveSearch( drumIdx - 1, shiftsLeft, currentShifts, line0, lineMinus1, linePlus1 )
            end
            return
        end

        local step = 1
        local maxShift = shiftsLeft
        if drumIdx == 1 then
            if shiftsLeft > self._state.maxCorrections then return end
            if shiftsLeft > 0 then step = 2 * shiftsLeft end
        else
            if shiftsLeft > self._state.maxCorrections then maxShift = self._state.maxCorrections end
        end

        for shift = -maxShift, maxShift, step do
            local nL0 = self:CopyTable( line0 )
            local nLM = self:CopyTable( lineMinus1 )
            local nLP = self:CopyTable( linePlus1 )
            local nextLeft = shiftsLeft - math.abs( shift )
            local has = ( shift == 0 )
            local cn

            if nL0 ~= nil then
                cn = self._state.drumShiftMap[drumIdx][shift]
                if cn then nL0[cn] = ( nL0[cn] or 0 ) + 1; has = true end
            end
            if nLM ~= nil then
                cn = self._state.drumShiftMap[drumIdx][shift - 1]
                if cn then nLM[cn] = ( nLM[cn] or 0 ) + 1; has = true end
            end
            if nLP ~= nil then
                cn = self._state.drumShiftMap[drumIdx][shift + 1]
                if cn then nLP[cn] = ( nLP[cn] or 0 ) + 1; has = true end
            end

            if has then
                currentShifts[drumIdx] = shift
                self:_RecursiveSearch( drumIdx - 1, nextLeft, currentShifts, nL0, nLM, nLP )
            end
        end
    else
        self:_RegisterBest( line0, currentShifts )
        self:_RegisterBest( lineMinus1, currentShifts )
        self:_RegisterBest( linePlus1, currentShifts )
    end
end


function AlchemySearchService:_RegisterBest( componentMap, shiftMap )
    if componentMap == nil then return end
    local filt = self._state.filteredRecipes
    if not filt then return end

    local best = nil
    for _, recipe in pairs( filt ) do
        local match = true
        for cn, need in pairs( recipe.cli ) do
            if ( componentMap[cn] or 0 ) < need then match = false; break end
        end
        if match and ( best == nil or recipe.score > best.score ) then
            best = recipe
        end
    end
    if best == nil then return end

    for _, entry in pairs( self._state.foundResults ) do
        if entry.rc.name == best.name then return end
    end

    table.insert( self._state.foundResults, {
        rc = best,
        sh = self:CopyTable( shiftMap ),
        cmb = self:CopyTable( componentMap ),
    })
end