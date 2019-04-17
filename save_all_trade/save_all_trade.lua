if string.find(package.path,'C:\\Program Files (x86)\\Lua\\5.1\\?.lua')==nil then
   package.path=package.path..';C:\\Program Files (x86)\\Lua\\5.1\\?.lua;'
end
if string.find(package.path,'C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\Lua\\?.lua;')==nil then
   package.path=package.path..';C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\Lua\\?.lua;'
end

require'QL'

--###############################################
local sSecCode = {'SR', 'RI', 'GZ', 'Si', 'VB'}
local suffix = 'M6'
--###############################################

local tickers = {}
local sClassCode = 'SPBFUT'     --getParam(sSecCode)       --'SPBFUT'
local sPath = 'C:\\QuikFinam\\All_Trade' -- указать путь к папке, куда сохранять архив всех сделок

local write = write
local string_format = string.format
local _bitset = bit_set
local nLastNumTrade = 0

local function _AllTrade_Write(sPath, secCode)
    os.execute('mkdir '..sPath)
    local f = {} 
    local f_name = {}
    local first_trade_dt = getItem('all_trades', 0).datetime
	local tbl = {}

    for ticker,_ in pairs(secCode) do
        f_name[secCode[ticker]] = secCode[ticker]..'_'..string_format('%4d%02d%02d', 
                    first_trade_dt.year , first_trade_dt.month, first_trade_dt.day)..'.csv'
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
	  
      for ticker, _ in pairs(secCode) do
          f[secCode[ticker]]:close()
          message('Table of All_Trade saved in file:\n"'..f_name[secCode[ticker]]..'"', 1)
      end
	  
      return true
    end
  
end

function main()  
    local first_trade_dt = getItem('all_trades', 0).datetime
    sPath = sPath..string_format('%02d', first_trade_dt.year)..'\\'
                                ..string_format('%02d', first_trade_dt.month)..'\\'

    for i=1, #sSecCode do tickers[sSecCode[i]..suffix] = sSecCode[i]..suffix end
    _AllTrade_Write(sPath, tickers)    
end