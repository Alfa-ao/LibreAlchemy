-- MathUtils.lua

Class( "MathUtils", {} )

-- Локальная функция: безопасный математический модуль (остаток от деления).
-- В Lua оператор % для отрицательных чисел может возвращать отрицательный результат. 
-- Эта функция гарантирует, что результат всегда будет в диапазоне [0, b-1].
function safeModulo( a, b )
    -- a: number (int) - делимое (например, basePos + shift)
    -- b: number (int) - делитель (например, количество компонентов в барабане)
    return ( ( a % b ) + b ) % b
end


-- (shallow copy) Поверхностное (неглубокое) копирование таблицы.
function MathUtils:ShallowCopy( tbl )
	if type( tbl ) ~= "table" then return {} end
	
	--[[ {
		[1] => number(-0)
		[2] => number(-1)
		[3] => number(-1)
		[4] => number(0)
		[5] => number(0)
    }
	
	{
      	[Биоморфичность] => number(1)
		[Повреждение] => number(1)
		[Призрачность] => number(1)
		[Равновесие] => number(1)
		[Технологичность] => number(1)
    } ]]
		
	local copy = {}
	for k, v in pairs( tbl ) do
		copy[ k ] = v
	end
	
	return copy
end