-- Utils/MathUtils.lua

Class( "MathUtils", {} )

-- Безопасный математический модуль (остаток от деления).
-- В Lua оператор % для отрицательных чисел может возвращать отрицательный результат. 
-- Эта функция гарантирует, что результат всегда будет в диапазоне [0, b-1].
function MathUtils.safeModulo( a, b ) --- int
    -- a: number (int) - делимое (например, basePos + shift)
    -- b: number (int) - делитель (например, количество компонентов в барабане)
    return ( ( a % b ) + b ) % b
end


-- (shallow copy) Поверхностное (неглубокое) копирование таблицы.
-- В общем: Просто так скопировать таблицу в lua нельзя, иначе копия будет ссылаться к родителю.
function MathUtils.shallowCopy( tbl ) --- table
	if type( tbl ) ~= "table" then return {} end
	
	local copy = {}
	for k, v in pairs( tbl ) do
		copy[ k ] = v
	end
	
	return copy
end