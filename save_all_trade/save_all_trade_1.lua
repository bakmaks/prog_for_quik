if string.find(package.path,'C:\\Program Files (x86)\\Lua\\5.1\\?.lua')==nil then
   package.path=package.path..';C:\\Program Files (x86)\\Lua\\5.1\\?.lua;'
end
if string.find(package.path,'C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\Lua\\?.lua;')==nil then
   package.path=package.path..';C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\Lua\\?.lua;'
end

require'QL'

--###############################################
local sSecCode = {'SR', 'RI', 'GZ', 'Si', 'VB'}
local suffix = 'M9'
--###############################################

local tickers = {}
local sClassCode = 'SPBFUT'     --getParam(sSecCode)       --'SPBFUT'
local sPath = 'C:\\SBERBANK\\QUIK\\All_Trade' -- указать путь к папке, куда сохран¤ть архив всех сделок

local write = write
local string_format = string.format
local _bitset = bit_set
local nLastNumTrade = 0

local is_run = true
local call = false

--********************************************* ‘ункции обработчики событий Quik *************************************
function OnStop()
	is_run = false
	DestroyTable(SaveAllTrades)
end

function OnInit()
	SaveAllTrades = AllocTable()
	AddColumn(SaveAllTrades, 1, "Имя файла", true, QTABLE_CACHED_STRING_TYPE, 40)
	AddColumn(SaveAllTrades, 2, "Время записи записи", true, QTABLE_CACHED_STRING_TYPE, 20)
	CreateWindow(SaveAllTrades)
	
	SetTableNotificationCallback(SaveAllTrades, tableManagement)		-- назначение функции обратного вызова
	
	SetWindowPos(SaveAllTrades, 100, 700, 400, 100)
	InsertRow(SaveAllTrades, -1)
end

function tableManagement(t_id, msg, par1, par2)
	if t_id == SaveAllTrades and  msg == QTABLE_CLOSE then
		OnStop()
    end
end
--***********************************************************************************************************************

local function _AllTrade_Write(sPath, secCode, now_date)
    os.execute('mkdir '..sPath)
    local f = {} 
    local f_name = {}
	local tbl = {}

    for ticker,_ in pairs(secCode) do
        f_name[secCode[ticker]] = secCode[ticker]..'_'..string_format('%4d%02d%02d', 
                    now_date.year , now_date.month, now_date.day)..'.csv'
        f[secCode[ticker]], error = io.open(sPath..f_name[secCode[ticker]], 'w')
        if not f[secCode[ticker]] then
            message(error, 3)
            return nil
        end
        f[secCode[ticker]]:write('TICKER;DATE;TIME;LAST;VOL;OPERATION;MS\n')
    end 
    
    local n = getNumberOf('all_trades')
	
    if n > nLastNumTrade then
	
      local alltrade, datetime, flags
	  
      for i = nLastNumTrade, n-1 do
        alltrade = getItem('all_trades', i)
		if alltrade.datetime.day == now_date.day then
			-- toLog('alltrade_log.txt','alltrade.sec_code = '..alltrade.sec_code..
					-- '; alltrade.datetime.day = '..alltrade.datetime.day..
					-- '; alltrade.datetime.month = '..alltrade.datetime.month,1)
			tbl[alltrade.sec_code] = alltrade.sec_code
			
			if alltrade.sec_code == secCode[alltrade.sec_code] and alltrade.class_code == sClassCode then
			  datetime, flags = alltrade.datetime, alltrade.flags
			  
			  if _bitset(flags, 0) then operation = 'S'
			  elseif _bitset(flags, 1) then operation = 'B'
			  else operation = '' end
			  f[secCode[alltrade.sec_code]]:write(
								string_format('%s;%02d.%02d.%4d;%02d:%02d:%02d;%d;%d;%s;%03d\n',
											secCode[alltrade.sec_code], datetime.day, datetime.month,
											datetime.year, datetime.hour, datetime.min, datetime.sec,
											alltrade.price, alltrade.qty, operation, datetime.ms))
			end
		end
      end
	  local rows, cols = GetTableSize (SaveAllTrades)
	  local row = 1
      for ticker, _ in pairs(secCode) do
          f[secCode[ticker]]:close()
		  if row > rows then
			InsertRow(SaveAllTrades, -1)
		  end
		  SetCell(SaveAllTrades, row, 1, f_name[secCode[ticker]])
		  row = row + 1
      end
	  SetCell(SaveAllTrades, math.floor(row / 2), 2, string.format('%02d:%02d:%02d', now_date.hour, now_date.min, now_date.sec))
      return true
    end
  
end

function main()  
    local first_trade_dt = {}
	-- if getNumberOf('all_trades') ~= 0 then
		-- first_trade_dt = getItem('all_trades', 0).datetime
	-- else
		first_trade_dt = os.date('*t')
	-- end
    sPath = sPath..string_format('%02d', first_trade_dt.year)..'\\'
                                ..string_format('%02d', first_trade_dt.month)..'\\'
	
    for i=1, #sSecCode do tickers[sSecCode[i]..suffix] = sSecCode[i]..suffix end
	
	local full_date = {}
	local string_date, string_time = '', ''
	local t1 = os.time()
	
	while is_run do	
		full_date = os.date('*t')
		string_date = string.format('%02d/%02d/%04d', full_date.day, full_date.month, full_date.year)
		string_time = string.format('%02d:%02d:%02d', full_date.hour, full_date.min, full_date.sec)
		SetWindowCaption(SaveAllTrades, "сохранение данных ..."..' '..string_time..'   '..string_date)
		if (isConnected() and full_date.hour >= 18) and os.difftime(os.time(), t1) > 800 then
			t1 = os.time()
			SetColor(SaveAllTrades, QTABLE_NO_INDEX, 2, RGB(255, 211, 0), QTABLE_DEFAULT_COLOR, RGB(255, 211, 0), QTABLE_DEFAULT_COLOR)
			_AllTrade_Write(sPath, tickers, full_date)
			SetColor(SaveAllTrades, QTABLE_NO_INDEX, 2, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
		else
			SetWindowCaption(SaveAllTrades, "сохранение данных ..."..' '..string_time..'   '..string_date)
		end
		sleep(100)
	end
end