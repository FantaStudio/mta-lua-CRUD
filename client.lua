--======= CRUD BY MindTerror

local sw,sh = guiGetScreenSize()
local px,py = sw/1920,sh/1080

local server = setmetatable(
	{},
	{
		__index = function(t, k)
			t[k] = function(...) triggerServerEvent('onClientCallsServerFunction_CRUD', resourceRoot, k, ...) end
			return t[k]
		end
	}
)
local searchFilter = nil
local tempTable = nil
--================================== INTERFACE DEFENITION ======================================================

--// CRUD
local CRUD = {}
CRUD.visible = true
CRUD.enabled = true
CRUD.page = 1

CRUD.bg = {
	x = (sw-576)/2,
	y = (sh-528)/2,
	w = 576,
	h = 528,
	color =  tocolor(55, 150, 199, 204)
}

CRUD.title = {
	text = "Пользователи",
	x = CRUD.bg.x,
	y = CRUD.bg.y,
	w = CRUD.bg.w,
	h = 49,
	color = tocolor(109, 188, 243, 176),
	textColor = tocolor(255, 255, 255,255)
}

CRUD.buttons = {}
-- CRUD Manipulation buttons
CRUD.buttons[1] = {x = CRUD.bg.x+36, y = CRUD.title.y+CRUD.title.h+11, w = 161, h = 38, text = "Добавить"}
CRUD.buttons[2] = {x = CRUD.buttons[1].x+CRUD.buttons[1].w+10, y = CRUD.title.y+CRUD.title.h+11, w = 161, h = 38, text = "Редактировать"}
CRUD.buttons[3] = {x = CRUD.buttons[2].x+CRUD.buttons[2].w+10, y = CRUD.title.y+CRUD.title.h+11, w = 161, h = 38, text = "Удалить"}


CRUD.grid = {
	x = CRUD.bg.x+5,
	y = CRUD.buttons[1].y+CRUD.buttons[1].h+11,
	w = 565,
	h = 379,
	titleH = 42,
	rowH = 33.7,

	color = tocolor(151, 195, 240, 183),
	titleColor = tocolor(151, 195, 240, 183),
	textColor = tocolor(255,255,255,255),
	rowColors = {tocolor(167, 204, 242, 221),tocolor(191, 217, 244, 221),tocolor(213, 230, 248, 221)},

	columns = {
		{"Имя",0.35,"Name"},
		{"Фамилия",0.35,"Surname"},
		{"Адрес",0.3,"Adress"},
	},
	rows = {},
	selected = nil
}

-- CRUD Page buttons
CRUD.buttons[4] = {x = CRUD.grid.x, y = CRUD.grid.y+CRUD.grid.h+10, w = 34, h = 22, image = "files/arrow.png", imgRot = 180, visible = false}
CRUD.buttons[5] = {x = CRUD.buttons[4].x+CRUD.buttons[4].w+5, y = CRUD.buttons[4].y, w = 34, h = 22, image = "files/arrow.png", visible = false}

CRUD.edits = {
	edit.create(CRUD.buttons[4].x+190,CRUD.grid.y+CRUD.grid.h+10,100,22,tocolor(109, 188, 243,200),nil,nil,"Имя",nil,"letter"),
	edit.create(CRUD.buttons[4].x+295,CRUD.grid.y+CRUD.grid.h+10,100,22,tocolor(109, 188, 243,200),nil,nil,"Фамилия",nil,"letter"),
	edit.create(CRUD.buttons[4].x+400,CRUD.grid.y+CRUD.grid.h+10,100,22,tocolor(109, 188, 243,200),nil,nil,"Адрес"),
}

CRUD.buttons[6] = {x = CRUD.edits[3].x+105, y = CRUD.edits[3].y, w = 60, h = 22, text = "Поиск", fontSize = 6}

-- Some CRUD methods
CRUD.getPageRowCount = function() -- Gets the rows count that one page can contain
	return (CRUD.grid.h-CRUD.grid.titleH)/CRUD.grid.rowH
end

CRUD.getPageRowsCount = function() -- Gets the maximum rows to draw on current page
	return math.min(#CRUD.grid.rows-CRUD.getPageRowCount()*(CRUD.page-1),CRUD.getPageRowCount())
end

CRUD.getPagesCount = function() -- Gets CRUD's pages count
	return math.ceil(#CRUD.grid.rows/CRUD.getPageRowCount())
end

CRUD.getRowPage = function(row) -- Gets page, where row exists
	assert(row and type(row) == "number","wrong 1 arg(row) @CRUD.getRowPage")
	local rowCount = CRUD.getPageRowCount()
	local page = 0
	while(row > 0) do
		page = page + 1
		row = row - rowCount
	end
	return page
end

--// User window
local UserWindow = {
	enabled = true,
	visible = false,
	x = CRUD.bg.x + (CRUD.bg.w - CRUD.bg.w/1.2)/2,
	y = CRUD.bg.y + (CRUD.bg.h - CRUD.bg.h/2.2)/2,
	w = CRUD.bg.w/1.2,
	h = CRUD.bg.h/2.2,
	color = tocolor(55, 150, 199, 204),
	type = "edit",
}

UserWindow.title = {
	h = 40,
	color = tocolor(109, 188, 243, 176),
	text = "Добавление пользователя",
}

UserWindow.edits = {
	edit.create(UserWindow.x+50,UserWindow.y+60,UserWindow.w-100,30,tocolor(109, 188, 243,200),nil,nil,"Имя",nil,"letter"),
	edit.create(UserWindow.x+50,UserWindow.y+100,UserWindow.w-100,30,tocolor(109, 188, 243,200),nil,nil,"Фамилия",nil,"letter"),
	edit.create(UserWindow.x+50,UserWindow.y+140,UserWindow.w-100,30,tocolor(109, 188, 243,200),nil,nil,"Адрес"),
}

UserWindow.buttons = {}
UserWindow.buttons[1] = {x = UserWindow.x+50, y = UserWindow.y+180, w = 161, h = 38, text = "ОК"}
UserWindow.buttons[2] = {x = UserWindow.x+270, y = UserWindow.y+180, w = 161, h = 38, text = "Отмена"}

--// Popup
local Popup = {
	visible = false,
	x = CRUD.bg.x + (CRUD.bg.w - CRUD.bg.w/1.2)/2,
	y = CRUD.bg.y + (CRUD.bg.h - CRUD.bg.h/2.2)/2,
	w = CRUD.bg.w/1.2,
	h = CRUD.bg.h/2.2,
	color = tocolor(55, 150, 199, 204),
	type = "delete"
}

Popup.title = {
	h = 40,
	color = tocolor(109, 188, 243, 176),
	text = "Подтвердите действие",
}

Popup.text = ""

-- Popup buttons
Popup.buttons = {}
Popup.buttons[1] = {x = UserWindow.x+50, y = UserWindow.y+180, w = 161, h = 38, text = "ОК"}
Popup.buttons[2] = {x = UserWindow.x+270, y = UserWindow.y+180, w = 161, h = 38, text = "Отмена"}

--================================== MAIN ======================================================

local function renderButtons(buttons)
	for _,button in ipairs(buttons) do
		if button.visible ~= false then
			local alphaAnim = 219
			if isMouseInPosition(button.x*px, button.y*py, button.w*px, button.h*py) then
				alphaAnim = 190
			end
			dxDrawRectangle(button.x*px, button.y*py, button.w*px, button.h*py, tocolor(151, 195, 240, alphaAnim), false)
			if not button.image then
				dxDrawText(button.text, button.x*px, button.y*py, (button.x+button.w)*px, (button.y+button.h)*py, tocolor(255, 255, 255), 1, getFont("gilroyR",button.fontSize or 7), "center", "center", false, false, false, false, false)
			else
				dxDrawImage(button.x*px, button.y*py, button.w*px, button.h*py,button.image,button.imgRot or 0,0,0,tocolor(255,255,255,255),false)
			end
		end
	end
end

local function renderEdits(edits,enabled)
	local hasSelectedEdit = false
	if enabled == nil then enabled = true end
	for _,edit in ipairs(edits) do
		edit:render()
		edit.enabled = enabled
		if edit.selected then
			hasSelectedEdit = true 
		end
	end
	if hasSelectedEdit then
		guiSetInputMode("no_binds")
	else
		guiSetInputMode("allow_binds")
	end
end

local function drawElements()
	local hasSelectedEdit = false
	--// CRUD Main panel
	if CRUD.visible then
		--// BG
		dxDrawRectangle(CRUD.bg.x*px, CRUD.bg.y*py, CRUD.bg.w*px, CRUD.bg.h*py, CRUD.bg.color, false)
		--// Title bar
		dxDrawRectangle(CRUD.title.x*px, CRUD.title.y*py, CRUD.title.w*px, CRUD.title.h*py, CRUD.title.color, false)
		dxDrawText(CRUD.title.text, CRUD.title.x*px, CRUD.title.y*py, (CRUD.title.x+CRUD.title.w)*px, (CRUD.title.y + CRUD.title.h)*py, CRUD.title.textColor, 1, getFont("gilroyB",9), "center", "center", false, false, false, false, false)

		--// Grid
		dxDrawRectangle(CRUD.grid.x*px, CRUD.grid.y*py, CRUD.grid.w*px, CRUD.grid.h*py, CRUD.grid.color, false)
		dxDrawRectangle(CRUD.grid.x*px, CRUD.grid.y*py, CRUD.grid.w*px, CRUD.grid.titleH*py, CRUD.grid.titleColor, false)

		local rowsCount = nil
		local onePageRowCount = nil
		if CRUD.grid.rows and #CRUD.grid.rows > 0 and CRUD.enabled then
			rowsCount = CRUD.getPageRowsCount()
			onePageRowCount = CRUD.getPageRowCount()
		end
		--// Rows
		if rowsCount then
			for i = 1,rowsCount do
				local rowColor = CRUD.grid.rowColors[1]
				local realI = (CRUD.page-1)*onePageRowCount+i
				if isMouseInPosition(CRUD.grid.x*px,(CRUD.grid.y+CRUD.grid.titleH+(CRUD.grid.rowH*(i-1)))*py,CRUD.grid.w*px,CRUD.grid.rowH*py) then
					if getKeyState("mouse1") and CRUD.enabled then
						CRUD.grid.selected = realI
					end
					rowColor = CRUD.grid.rowColors[2]
				end
				if CRUD.grid.selected == realI then
					rowColor = CRUD.grid.rowColors[3]
				end
				dxDrawRectangle(CRUD.grid.x*px,(CRUD.grid.y+CRUD.grid.titleH+(CRUD.grid.rowH*(i-1)))*py,CRUD.grid.w*px,CRUD.grid.rowH*py,rowColor,false)
			end
			CRUD.buttons[4].visible = true
			CRUD.buttons[5].visible = true
			dxDrawText("стр "..CRUD.page.." из "..CRUD.getPagesCount(), (CRUD.buttons[5].x+CRUD.buttons[5].w+10)*px, CRUD.buttons[5].y*py, (CRUD.buttons[5].x+CRUD.buttons[5].w+106)*px, (CRUD.buttons[5].y+CRUD.buttons[5].h+5)*py, tocolor(255, 255, 255, 255), 1, getFont("gilroyR",6), "left", "center", true, false, false, false, false)
		else
			CRUD.buttons[4].visible = false
			CRUD.buttons[5].visible = false
		end

		-- Search
		renderEdits(CRUD.edits,CRUD.enabled)
		if CRUD.edits[1].text == "" and CRUD.edits[2].text == "" and CRUD.edits[3].text == "" then
			if(searchFilter ~= nil) then
				clearSearchFilter()
			end
		end

		--// Columns
		local columnX = CRUD.grid.x
		for columnNumber,column in ipairs(CRUD.grid.columns) do
			--// Column Headers
			dxDrawText(column[1], columnX*px, CRUD.grid.y, (columnX+column[2]*CRUD.grid.w)*px, CRUD.grid.y+CRUD.grid.titleH, CRUD.grid.textColor, 1, getFont("gilroyR",7), "center", "center", false, false, false, false, false)

			if rowsCount then
				for i = 1,rowsCount do
					local realI = (CRUD.page-1)*onePageRowCount+i
					dxDrawText(CRUD.grid.rows[realI][column[3]], columnX*px, (CRUD.grid.y + CRUD.grid.titleH + CRUD.grid.rowH*(i-1))*py, (columnX+column[2]*CRUD.grid.w)*px, (CRUD.grid.y + CRUD.grid.titleH + CRUD.grid.rowH*i)*py, CRUD.grid.textColor, 1, getFont("gilroyR",7), "center", "center", false, false, false, false, false)
				end
			end
			columnX = columnX + column[2]*CRUD.grid.w
		end

		--// Manipulation Buttons
		renderButtons(CRUD.buttons)
		
		--// Disabled effect
		if not CRUD.enabled and UserWindow.enabled ~= false then
			dxDrawRectangle(CRUD.bg.x*px, CRUD.bg.y*py, CRUD.bg.w*px, CRUD.bg.h*py,tocolor(0,0,0,200),false)
		end
	end

	--// User Window
	if UserWindow.visible then
		CRUD.enabled = false
		--// BG
		dxDrawRectangle(UserWindow.x*px,UserWindow.y*py,UserWindow.w*px,UserWindow.h*py,UserWindow.color,false)
		--// Title
		dxDrawRectangle(UserWindow.x*px,UserWindow.y*py,UserWindow.w*px,UserWindow.title.h*py,UserWindow.title.color,false)
		dxDrawText(UserWindow.title.text,UserWindow.x*px,UserWindow.y*py,(UserWindow.x + UserWindow.w)*px,(UserWindow.y + UserWindow.title.h)*py,tocolor(255,255,255),1,getFont("gilroyR",8),"center","center",false,false,false,false,false)
		--// Edit boxes
		renderEdits(UserWindow.edits,UserWindow.enabled)
		--// Buttons
		renderButtons(UserWindow.buttons)
		--// Disabled effect
		if not UserWindow.enabled then
			dxDrawRectangle(CRUD.bg.x*px, CRUD.bg.y*py, CRUD.bg.w*px, CRUD.bg.h*py,tocolor(0,0,0,200),false)
		end
	end

	--// Popup
	if Popup.visible then
		UserWindow.enabled = false
		CRUD.enabled = false
		--// BG
		dxDrawRectangle(Popup.x*px,Popup.y*py,Popup.w*px,Popup.h*py,Popup.color,false)
		--// Title
		dxDrawRectangle(Popup.x*px,Popup.y*py,Popup.w*px,Popup.title.h*py,Popup.title.color,false)
		dxDrawText(Popup.title.text,Popup.x*px,Popup.y*py,(Popup.x + Popup.w)*px,(Popup.y + Popup.title.h)*py,tocolor(255,255,255),1,getFont("gilroyR",8),"center","center",false,false,false,false,false)
		--// Text
		dxDrawText(Popup.text,(Popup.x+20)*px,(Popup.y + Popup.title.h + 20)*py,(Popup.x + Popup.w - 20)*px,(Popup.y + Popup.title.h + Popup.h - 100)*py,tocolor(255,255,255),1,getFont("gilroyR",7),"center","center",false,true,false,false,false)
		--// Buttons
		renderButtons(Popup.buttons)
	end
end

local function initButtonClick(buttons)
	assert(buttons and type(buttons) == "table","wrong 1 arg(buttons) @initButtonClick")
	for _,button in ipairs(buttons) do
		if button.click and isMouseInPosition(button.x*px, button.y*py, button.w*px, button.h*py) then
			button.click()
			return;
		end
	end
end

local function onMouseClick(btn,state)
	if btn ~= "left" or state ~= "up" then return end
	if CRUD.enabled and CRUD.visible then
		initButtonClick(CRUD.buttons)
	elseif UserWindow.visible and UserWindow.enabled then
		initButtonClick(UserWindow.buttons)
	elseif Popup.visible then
		initButtonClick(Popup.buttons)
	end
end

local function popupShow(title,text,type)
	Popup.title.text = title or ""
	Popup.text = text or ""
	Popup.type = type or ""
	Popup.visible = true
end

local currentUserID = -1
local function userWindowShow(title,user)
	UserWindow.title.text = title or ""
	if user then
		UserWindow.edits[1].text = user.Name
		UserWindow.edits[2].text = user.Surname
		UserWindow.edits[3].text = user.Adress
		currentUserID = user.ID
		UserWindow.type = "edit"
	else
		UserWindow.type = "add"
	end
	UserWindow.visible = true
	UserWindow.edits[1]:select()
end

-- Add Init
CRUD.buttons[1].click = function()
	for _,cedit in ipairs(UserWindow.edits) do
		cedit.text = ""
	end
	userWindowShow("Добавление пользователя")
end

-- Edit init
CRUD.buttons[2].click = function()
	local user = getSelectedUserInGrid()
	if not user then _chat("Выберите пользователя из списка") return end
	userWindowShow("Редактирование пользователя",user)
end

-- Delete
CRUD.buttons[3].click = function()
	local user = getSelectedUserInGrid()
	if not user then _chat("Выберите пользователя из списка") return end
	currentUserID = user.ID
	popupShow("Подтвердите действие","Вы действительно хотите удалить пользователя?","delete")
end

-- Previous page
CRUD.buttons[4].click = function()
	if CRUD.page < 2 then return end
	CRUD.page = CRUD.page - 1
end

-- Next page
CRUD.buttons[5].click = function()
	if CRUD.page >= CRUD.getPagesCount() then return end
	CRUD.page = CRUD.page + 1
end

CRUD.buttons[6].click = function()
	local name = CRUD.edits[1].text
	local surname = CRUD.edits[2].text
	local adress = CRUD.edits[3].text
	if name ~= "" or surname ~= "" or adress ~= "" then
		searchFilter = {name,surname,adress}
		if tempTable then
			triggerEvent("onRefreshPlayerInfo",localPlayer,tempTable)
		else
			triggerEvent("onRefreshPlayerInfo",localPlayer,CRUD.grid.rows)
		end
	end
end

-- UserWindow OK button
UserWindow.buttons[1].click = function()
	if UserWindow.edits[1].text == "" then return _chat("Введите имя пользователя!") end
	if UserWindow.edits[2].text == "" then return _chat("Введите фамилию пользователя!") end
	if UserWindow.edits[3].text == "" then return _chat("Введите адрес пользователя!") end
	if UserWindow.type  == "edit" then
		popupShow("Подтвердите действие","Вы действительно хотите сохранить изменения?","edit")
	elseif UserWindow.type == "add" then
		popupShow("Подтвердите действие","Вы действительно хотите добавить пользователя?","add")
	end
end

-- UserWindow Cancel button
UserWindow.buttons[2].click = function()
	if UserWindow.type == "edit" then
		currentUserID = -1
	end
	UserWindow.type = ""
	UserWindow.visible = false
	CRUD.enabled = true
end

-- Popup OK button
Popup.buttons[1].click = function()
	if Popup.type == "add" or Popup.type == "edit" then
		local name = UserWindow.edits[1].text
		local surname = UserWindow.edits[2].text
		local adress = UserWindow.edits[3].text
		if Popup.type == "add" then
			server.addUser(name,surname,adress)
		else
			if currentUserID == -1 then return end
			server.editUser(currentUserID,name,surname,adress)
		end
	elseif Popup.type == "delete" then
		if currentUserID == -1 then return end
		server.deleteUser(currentUserID)
	end
	Popup.type = ""
	Popup.visible = false
	UserWindow.enabled = true
	UserWindow.visible = false
	UserWindow.type = ""
	CRUD.enabled = true
	currentUserID = -1
end

-- Popup cancel button
Popup.buttons[2].click = function()
	Popup.type = ""
	Popup.visible = false
	UserWindow.enabled = true
	if not UserWindow.visible then
		CRUD.enabled = true
		if Popup.type == "delete" or Popup.type == "edit" then
			currentUserID = -1
		end
	end
end

local function selectUserInGrid(ID)
	assert(ID and type(ID) == "number","wrong 1 arg(ID) @selectUserInGrid")
	if not CRUD.grid.rows or #CRUD.grid.rows < 1 then return end
	for row,data in ipairs(CRUD.grid.rows) do
		if data["ID"] == ID then
			CRUD.grid.selected = row
			CRUD.page = CRUD.getRowPage(row) -- set the page, where row exists
			return
		end
	end
	CRUD.grid.selected = nil
end

function getSelectedUserInGrid()
	if not CRUD.grid.selected then return false end
	if CRUD.grid.rows and CRUD.grid.rows[CRUD.grid.selected] then
		return CRUD.grid.rows[CRUD.grid.selected]
	else
		return false
	end
end

function clearSearchFilter()
	searchFilter = nil
	CRUD.grid.rows = tempTable or {}

	local prevSelected = getSelectedUserInGrid()
	if prevSelected then
		selectUserInGrid(prevSelected.ID)
	end
end

local function filterTableBySearch(tableToFilter)
	if not searchFilter then return tableToFilter end
	tempTable = tableToFilter
	-- filter
	local filteredTable = {}
	for i,v in ipairs(tableToFilter) do
		local add = true
		if searchFilter[1] and searchFilter[1] ~= "" and not utf8.match(v.Name,"^"..searchFilter[1]..".*") then
			add = false
		end
		if searchFilter[2] and searchFilter[2] ~= "" and not utf8.match(v.Surname,"^"..searchFilter[2]..".*") then
			add = false
		end
		if searchFilter[3] and searchFilter[3] ~= "" and not utf8.match(v.Adress,"^"..searchFilter[3]..".*") then
			add = false
		end
		if add then
			table.insert(filteredTable,v)
		end
	end
	return filteredTable
end

-- Refresh grid info
addEvent("onRefreshPlayerInfo",true)
addEventHandler("onRefreshPlayerInfo",root,function(table)
	local prevSelected = getSelectedUserInGrid()
	CRUD.grid.rows = filterTableBySearch(table)
	if prevSelected then
		selectUserInGrid(prevSelected.ID)
	end
end)

_chat = function(message)
	outputChatBox("#00FFDE[CRUD]#FFFFFF "..message,255,255,255,true)
end

function toggleCRUD()
	if isEventHandlerAdded("onClientRender",root,drawElements) then
		removeEventHandler("onClientRender",root,drawElements)
		if isEventHandlerAdded("onClientClick",root,onMouseClick) then
			removeEventHandler("onClientClick",root,onMouseClick)
		end
		CRUD.grid.rows = {}
		UserWindow.type = ""
		Popup.type = ""
		currentUserID = -1
		showCursor(false)
		guiSetInputMode("allow_binds")
	else
		addEventHandler("onClientRender",root,drawElements)
		if not isEventHandlerAdded("onClientClick",root,onMouseClick) then 
			addEventHandler("onClientClick",root,onMouseClick)
		end
		showCursor(true)
		server.parseUsers()
	end
end
bindKey(toggledKey,"down",toggleCRUD)

addEventHandler("onClientResourceStop",resourceRoot,function()
	if not isEventHandlerAdded("onClientRender",root,drawElements) then return end
	if isCursorShowing() then
		showCursor(false)
	end
	guiSetInputMode("allow_binds")
end)