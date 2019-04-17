function main()
	-- показывает цену последней сделки по инструменту
	message(getParamEx('SPBFUT', 'SRZ5', "last").param_value, 1)
end