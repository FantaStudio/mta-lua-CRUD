local sw,sh = guiGetScreenSize()
local px,py = sw/1920,sh/1080

--// MindTerror's DX Lib
local fontsList = {
	{'gilroyB','files/Gilroy-Semibold.ttf'},
	{'gilroyR','files/Gilroy-Regular.ttf'},
}

--// Fonts
local dxFontsTable = {};
function getFont(name,size,type)
	assert(name and size,'Один из параметров пропущен')
	if not type then type = "cleartype_natural" end
	for i,v in ipairs(fontsList) do
		if v[1] == name then
			if dxFontsTable[name..size..type] then 
				return dxFontsTable[name..size..type];
			else
				local font = dxCreateFont(v[2],size*(sw/1080),false)
				dxFontsTable[name..size..type] = font;
				return font;
 			end
		end
	end
	return "default"
end

--// DX edit box
local edits = {}
edit = {}
edit.id = 0
edit.x = 0
edit.y = 0
edit.w = 400
edit.h = 100
edit.color = tocolor(0,0,0)

edit.text = ""
edit.textColor = tocolor(255,255,255)
edit.placeholderColor = tocolor(255,255,255,150)
edit.font = "default-bold"
edit.carretIndex = 0
edit.carretHeight = 0.3 -- relative
edit.carretWidth = 2
edit.placeholder = ""
edit.padding = 0.05 -- relative

edit.renderTarget = nil;
edit.scroll = 0
edit.selected = false;
edit.visible = true;
edit.enabled = true
edit.chars = "0123456789abcdefghijklmnopqrstuvwxyzабвгдеёжзийклмнопрстуфхцчшщъыьэюя;,-./#\=[] "

edit.keyTick = nil
edit.pdW = nil
edit.pdX = nil
function edit:render()
	if not self.visible then
		return
	end

	--// Draw edit bg
	dxDrawRectangle(self.x*px,self.y*py,self.w*px,self.h*py,self.color)

	--// Set render target for edit content
	dxSetRenderTarget(self.renderTarget, true)
	dxSetBlendMode("overwrite")

	--// Draw Edit text
	if self.text ~= "" then
		dxDrawText(self.text,-self.scroll*px,0,self.pdW*px,self.h*py,edit.textColor,1,self.font,"left","center",true)
	else
		dxDrawText(self.placeholder or "",-self.scroll*px,0,self.pdW*px,self.h*py,edit.placeholderColor,1,self.font,"left","center",true)
	end

	--// Draw carret
	if self.selected then
		local selectedWidth = dxGetTextWidth(utf8.sub(self.text,0,self.carretIndex),1,self.font)/px
		if selectedWidth+self.carretWidth >= self.pdW then
			self.scroll = selectedWidth - self.pdW + self.carretWidth
		else
			self.scroll = 0
		end
		local tick = getTickCount() / 400
		dxDrawRectangle((selectedWidth-self.scroll)*px,(self.h*(1-self.carretHeight)/2)*py,self.carretWidth*px,(self.h*self.carretHeight)*py,tocolor(60,60,60, math.abs(math.sin(tick)*220)))
	end

	--// Restore render target
	dxSetBlendMode("blend")
	dxSetRenderTarget()

	--// Draw edit content
	dxDrawImage(self.pdX*px,self.y*py,self.pdW*px,self.h*py,self.renderTarget)

	--// Click on edit text
	if getKeyState("mouse1") and self.enabled then
		local mouseX,mouseY = getCursorPosition();
		local cursorX,cursorY = mouseX*sw,mouseY*sh;

		local selectionWidth = cursorX - self.pdX
		if (cursorX > self.x*px and cursorX < (self.x + self.w)*px and cursorY > self.y*py and cursorY < (self.y + self.h)*py) then
			if self.selected ~= true then
				self:select()
			end

			local wSumm = 0
			local letterI = 0;
			for letter in utf8.gmatch(self.text,".") do
				wSumm = wSumm + dxGetTextWidth(letter,1,self.font)
				letterI = letterI + 1
				if cursorX/px - self.pdX + self.scroll <= wSumm/px then
					self.carretIndex = letterI
					return
				end
			end
			if(cursorX/px > wSumm + self.pdX and self.selected) then 
				self.carretIndex = utf8.len(self.text)
			elseif self.selected then
				self.carretIndex = 0
			end
		else
			self.selected = false
		end
	elseif not edit.keyTick and self.selected and self.enabled then
		--// Delete current letter
		if getKeyState("backspace") then
			edit.keyTick = getTickCount()
			self.text = utf8.remove(self.text,self.carretIndex,self.carretIndex)
			if self.carretIndex > 1 then
				self.carretIndex = self.carretIndex - 1
			end
		--// Move carret by left arrow
		elseif getKeyState("arrow_l") then
			edit.keyTick = getTickCount()
			if self.carretIndex > 1 then
				self.carretIndex = self.carretIndex - 1
			end
		--// Move carret by right arrow
		elseif getKeyState("arrow_r") then
			edit.keyTick = getTickCount()
			if self.carretIndex < utf8.len(self.text) then
				self.carretIndex = self.carretIndex + 1
			end
		end
	end
	if edit.keyTick and (getTickCount() - edit.keyTick >= 100) then
		edit.keyTick = nil
	end
end

function edit:select()
	self.carretIndex = utf8.len(self.text)
	self.selected = true;
	for _,editTo in ipairs(edits) do
		if editTo ~= self then
			editTo.selected = false
		end
	end
end

function edit.create(x,y,w,h,color,text,textColor,placeholder,placeholderColor,Etype)
	assert(x and type(x) == "number","wrong 1 argument(x) @edit:create")
	assert(y and type(y) == "number","wrong 2 argument(y) @edit:create")
	assert(w and type(w) == "number","wrong 3 argument(w) @edit:create")
	assert(h and type(h) == "number","wrong 4 argument(h) @edit:create")

	local newEdit = {}
	setmetatable(newEdit,{__index = edit})

	newEdit.x = x
	newEdit.y = y
	newEdit.w = w
	newEdit.h = h
	newEdit.pdX = x + w*newEdit.padding
	newEdit.pdW = w - w*newEdit.padding*2
	newEdit.renderTarget = dxCreateRenderTarget(newEdit.pdW*px,h*py,true)

	if color then
		newEdit.color = color
	end
	if text then
		newEdit.text = text
	end
	if textColor then
		newEdit.textColor = textColor
	end
	if placeholder then
		newEdit.placeholder = placeholder
	end
	if placeholderColor then
		newEdit.placeholderColor = placeholderColor
	end
	if Etype == "number" then
		newEdit.chars = "0123456789 "
	elseif Etype == "letter" then
		newEdit.chars = "abcdefghijklmnopqrstuvwxyzабвгдеёжзийклмнопрстуфхцчшщъыьэюя "
	end
	table.insert(edits,newEdit)
	newEdit.id = #edits
	return newEdit
end

function edit:destroy()
	if self.renderTarget and isElement(self.renderTarget) then
		destroyElement(self.renderTarget)
	end
	table.remove(edits,self.id)
	self = nil
end

function editAddKeyManager(btn)
	if not edits then return end
	if #edits < 1 then return end
	for i,edit in ipairs(edits) do
		if edit.visible and edit.selected and edit.enabled then
			if string.find(edit.chars,utf8.fold(btn)) then
				edit.text = utf8.insert(edit.text,edit.carretIndex+1,btn)
				if (edit.carretIndex < utf8.len(edit.text)) then
					edit.carretIndex = edit.carretIndex + 1
				end
			end
		end
	end
end
addEventHandler("onClientCharacter",root,editAddKeyManager)

--// Useful
function isMouseInPosition ( x, y, width, height )
	if ( not isCursorShowing( ) ) then
		return false
	end
	local cx, cy = getCursorPosition ( )
	local cx, cy = ( cx * sw ), ( cy * sh )
	
	return ( ( cx >= x and cx <= x + width ) and ( cy >= y and cy <= y + height ) )
end