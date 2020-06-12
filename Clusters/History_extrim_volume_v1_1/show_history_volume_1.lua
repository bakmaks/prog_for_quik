function showListOfFiles(params, id_table, num)
	local rows, col = GetTableSize (id_table)
	local fnd = 'да'
	if num > rows then InsertRow(id_table, -1) end
	SetCell(id_table, num, 1, params.file[num].name)
	if params.file[num].not_found then 
		fnd = 'нет' 
		SetColor(id_table, num, QTABLE_NO_INDEX, RGB(255, 211, 0), QTABLE_DEFAULT_COLOR, RGB(255, 211, 0), QTABLE_DEFAULT_COLOR)
	end
	SetCell(id_table, num, 2, fnd)
end

function getLine(lenth)
    local line = ''
    for i=1, lenth do line = line..'~~' end
    return line
end
			
function setLableColor(r, g, b, params)
	params.label.R = r
	params.label.G = g
	params.label.B = b
end

function addLableOnGr(params, cl_date)
	local cl_date = tonumber(cl_date)
	
	if params.ticker_store['label_length'] <= 0 then 
		message('Задайте величину "label_length" > 0 в файле config.xml')
		return 
	end
	--message('date = '..cl_date,1)
	for cl_position = 1, #params.clusters[cl_date] do
		setLableColor(255, 245, 0, params)
		hint = 'Дата: '..cl_date..'; Время: '..params.clusters[cl_date][cl_position].cl_time..
				';\nЦена: '..math.floor(params.clusters[cl_date][cl_position].cl_avg_price)..
				'; Объём: '..params.clusters[cl_date][cl_position].cl_sum_qty..
				';\nМакс. сделка: '..params.clusters[cl_date][cl_position].cl_max_qty
		if params.clusters[cl_date][cl_position].cl_sum_qty < params.ticker_store['MIDDLE_SIZE_TRADES'] then
			suffix = 's'			--'small_volume'
		elseif params.clusters[cl_date][cl_position].cl_sum_qty < params.ticker_store['BIG_SIZE_TRADES'] then
			suffix = 'm'			--'middle_volume'
		elseif params.clusters[cl_date][cl_position].cl_sum_qty >= params.ticker_store['BIG_SIZE_TRADES'] then
			suffix = 'O'			--'big_volume'
			local big = params.ticker_store['BIG_SIZE_TRADES']
			if params.clusters[cl_date][cl_position].cl_sum_qty < big * 1.5 then
				setLableColor(255, 8, 8, params)
			elseif params.clusters[cl_date][cl_position].cl_sum_qty < big * 2  then
				setLableColor(205, 0, 116, params)
			elseif params.clusters[cl_date][cl_position].cl_sum_qty >= big * 2 then
				setLableColor(255, 137, 0, params)
			end
		end
		params.label.TEXT = suffix..getLine(math.floor((params.clusters[cl_date][cl_position].cl_sum_qty / (params.ticker_store['label_length'] * 1000)) ^ 1.5))			
		params.label.YVALUE = params.clusters[cl_date][cl_position].cl_avg_price + params.ticker_store['price_shift']
		params.label.DATE = cl_date
		params.label.TIME = params.clusters[cl_date][cl_position].cl_time
		params.label.HINT = hint 
		table.insert(params.cluster_labels, AddLabel(params.ticker_store['graph_id'], params.label))
	end
	
	return 1
end

