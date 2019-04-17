local base = _G

module('Serializer')
-- модуль для сохранения таблицы в файл
-- могут быть сохранены переменные типа число, строка или булевский тип
-- таблица сохраняется в текущий поток вывода
-- если вы хотите, чтобы сохранение производилось в файл,
-- то поток вывода Lua должен быть предварительно настроен, например так:
-- открываем файл для записи данных
-- local f = io.open("data.lua", "w")
-- сохраняем предыдущий поток вывода
-- local prevOutput = io.output()
-- устанавливаем вывод стандартного потока в наш файл
-- io.output(f)
-- сериализация...
-- закрываем файл
-- f:close()
-- восстанавливаем предыдущий поток вывода
-- io.output(prevOutput)
-- ...

-- проверка, что переменная может быть сохранена как строка 
-- т.е это число, строка или булевский тип)
local function isValidType(valueType)
  return "number" == valueType or 
         "boolean" == valueType or 
         "string" == valueType
end

-- конвертация переменной в строку
local function valueToString (value)
  local valueType = base.type(value)
  
  if "number" == valueType or "boolean" == valueType then
    result = base.tostring(value)
  else  -- assume it is a string
    result = base.string.format("%q", value)
  end
  
  return result
end

function save (name, value, saved)
  saved = saved or {}       -- initial value
  base.io.write(name, " = ")
  local valueType = base.type(value)
  if isValidType(valueType) then
    base.io.write(valueToString(value), "\n")
  elseif "table" == valueType then
    if saved[value] then    -- value already saved?
      base.io.write(saved[value], "\n")  -- use its previous name
    else
      saved[value] = name   -- save name for next time
      base.io.write("{}\n")     -- create a new table
      for k,v in base.pairs(value) do      -- save its fields
        -- добавляем проверку ключа таблицы
        local keyType = base.type(k)
        if isValidType(keyType) then
          local fieldname = base.string.format("%s[%s]", name, valueToString(k))
          save(fieldname, v, saved)
        else
          base.error("cannot save a " .. keyType)
        end
      end
    end
  else
    base.error("cannot save a " .. valueType)
  end
end

function serializeTable(file_name, serializing_table)
	local prev = base.io.output()
	local f = base.io.open(file_name, "w")
	base.io.output(f)
	base.io.write('local ')
	save ('a', serializing_table)
	--base.io.write('\n')
	base.io.write('return a')
	base.io.write('\n')
	f:close()	
	base.io.output(prev)
end
