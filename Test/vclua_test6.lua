dofile "vclua_test5.lua"

function main()
	repeat 
		message('вот Текст  '..Text, 1)
		sleep(2000) 
	until not vcl 
end