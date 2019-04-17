function initLabelParams()
	local label = {		-- структура параметров метки
		IMAGE_PATH = nil,		--label_name
		ALIGNMENT = 'RIGHT',
		TRANSPARENCY = 0,
		TRANSPARENT_BACKGROUND = 1,
		FONT_FACE_NAME = "Arial",
		FONT_HEIGHT = 10
		}
		return label
end

function removeAllClusterLabels(id, labels)
    for _, t_label in ipairs(labels) do
        DelLabel(id, t_label)
    end
end
	
function setLableColor(r, g, b)
	Label_params.R = r
	Label_params.G = g
	Label_params.B = b
end