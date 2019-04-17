if string.find(package.path,'C:\\Program Files (x86)\\Lua\\5.1\\?.lua')==nil then
   package.path=package.path..';C:\\Program Files (x86)\\Lua\\5.1\\?.lua;'
end
if string.find(package.path,'C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\Lua\\?.lua;')==nil then
   package.path=package.path..';C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\Lua\\?.lua;'
end

Settings={}
Settings.Name = "MA"
Settings.mode = "C"
Settings.period = 5
Settings.str_field = "STRING field"


function dValue(i,param)
	local v = param or "C"
	if v == "O" then
		return O(i)
	elseif v == "H" then
		return H(i)
	elseif v == "L" then
		return L(i)
	elseif v == "C" then
		return C(i)
	elseif v == "V" then
		return V(i)
	elseif v == "M" then
		return (H(i) + L(i))/2
	elseif v == "T" then
		return (H(i) + L(i)+C(i))/3
	elseif v == "W" then
		return (H(i) + L(i)+2*C(i))/4
	else
	return C(i)
	end
end

function Init()
	return 1
end
function OnCalculate(idx)
	local per = Settings.period
	local mode = Settings.mode
	local lValue = iValue
	if idx >= per then
		local ma_value=0
		for j = (idx-per)+1, idx do
		ma_value = ma_value+dValue(j, mode)
		end
		return ma_value/per
	else
		return nil
	end
end
