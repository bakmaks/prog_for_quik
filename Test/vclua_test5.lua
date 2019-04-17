local vcl=require "qvcl"
local OnFormClose = function() message("BYE 2",1) mainForm:Release() vcl=nil end
local text = ''
local OnComboBoxChange = function()
							message(ComboBox.Text) 
							text = ComboBox.Text
						end

mainForm = vcl.Form{Caption="StakanMax", OnClose=OnFormClose }
ComboBox = vcl.ComboBox(mainForm, {Name = "ComboBoxx", top=10, left=10, Width=100, Text="Выбрать...", 
  OnChange= OnComboBoxChange, ShowHint=true, Hint="Всплыло вот..."})
for _,i in ipairs({"Текст 1","Текст 2","Текст 3"}) do    ComboBox.Items:Add(i) end

mainForm:Show()

