if string.find(package.path,'C:\\Program Files (x86)\\Lua\\5.1\\?.lua')==nil then
   package.path=package.path..';C:\\Program Files (x86)\\Lua\\5.1\\?.lua;'
end
if string.find(package.path,'C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\Lua\\?.lua;')==nil then
   package.path=package.path..';C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\Lua\\?.lua;'
end


require "vcl"

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

label = VCL.Label(mainForm,"Label")
label.Top = 30
label.Left = 50
label.Caption = "VCLua in QUIK"
label.Font.Size = 20

function onMenuExitClick()
    OnStop()
end

mainForm:Show()

is_run = true    

function main()
    while is_run do
        sleep(50)
    end
end

function OnStop()
    is_run = false
    mainForm:Free()
end