require "qvcl"

VCL =vcl

mForm = VCL.Form("mainForm")

mForm.Caption = "VCLua in QUIK"
mForm._= { position="podesktopcenter", height=150, width=300}

mMenu = VCL.MainMenu(mForm,"mainMenu")
mMenu:LoadFromTable({
    {name="mmfile", caption="&File", 
        submenu={
            {caption="Exit", onclick="onMenuExitClick", shortcut="Ctrl+F4"}, 
        }
    }
})

local edit = VCL.Edit(mForm,"ed")
local text = edit.Text
message(''..text, 1)
-- label = {}
-- label["SRZ4"] = VCL.Label(mainForm,"Label1")
-- label["RIZ4"] = VCL.Label(mainForm,"Label2")

-- label["SRZ4"].Top = 10
-- label["SRZ4"].Left = 10
-- label["RIZ4"].Top = 30
-- label["RIZ4"].Left = 10

-- cnt = {}
-- cnt["RIZ4"] = 0
-- cnt["SRZ4"] = 0

-- qty = {}
-- qty["RIZ4"] = 0
-- qty["SRZ4"] = 0

-- val = {}
-- val["RIZ4"] = 0
-- val["SRZ4"] = 0

function onMenuExitClick()
    OnStop()
end

mForm:Show()

is_run = true    

function main()
    while is_run do
        sleep(50)
    end
end

function OnStop()
    is_run = false
    mForm:Free()
end

-- function OnAllTrade(trade)
    -- if is_run == false then
        -- return
    -- end

    -- if (trade.seccode == "RIZ4") or (trade.seccode == "SRZ4") then
        -- cnt[trade.seccode] = cnt[trade.seccode] + 1
        -- qty[trade.seccode] = qty[trade.seccode] + trade.qty
        -- val[trade.seccode] = val[trade.seccode] + trade.value
        -- label[trade.seccode].Caption = trade.seccode .. " (" .. cnt[trade.seccode] .. ") " .. qty[trade.seccode] .. " = " .. val[trade.seccode]
    -- end
-- end