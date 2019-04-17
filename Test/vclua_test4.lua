require "qvcl"

VCL =vcl

mainForm = VCL.Form("mainForm")

mainForm.Caption = "VCLua in QUIK"
mainForm._= { position="podesktopcenter", height=150, width=300}

mainMenu = VCL.MainMenu(mainForm,"mainMenu")
mainMenu:LoadFromTable({
    {name="mmfile", caption="&File", 
        submenu={
            {caption="Exit", onclick="onMenuExitClick", shortcut="Ctrl+F4"}, 
        }
    }
})

local edit = VCL.Edit(mainForm, {Text='hello'})
local text = edit.Text
--message(''..text, 1)
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

mainForm:Show()

local is_run = true    

function main()
    while is_run do
        sleep(50)
    end
end

function OnStop()
    is_run = false
    mainForm:Free()
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