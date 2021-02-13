local db = false

function startUp()
	assert(dbConfig["host"] and dbConfig["username"] and dbConfig["password"] and dbConfig["dbname"],"CRUD wrong database setup")
	function addToStringWithSemi(str,addStr,name)
		if (addStr) then 
			return str..";"..name.."="..addStr
		else
			return str
		end
	end
	local host = dbConfig["host"]
	host = addToStringWithSemi(host,dbConfig["dbname"],"dbname")
	host = addToStringWithSemi(host,dbConfig["port"],"port")
	host = addToStringWithSemi(host,dbConfig["unix_socket"],"unix_socket")
	host = addToStringWithSemi(host,dbConfig["charset"],"charset")

	db = dbConnect("mysql",host,dbConfig["username"],dbConfig["password"])
	if db then
		outputDebugString(getThisResource().name.." connected to Database!")
		db:query(parseCallback,{1,"CREATE Users Table"},[[CREATE TABLE IF NOT EXISTS `Users`(ID INTEGER PRIMARY KEY AUTO_INCREMENT, Name TEXT, Surname TEXT, Adress TEXT)]])
	else
		outputDebugString(getThisResource().name.." isn't connected to Database!, check the connection",1)
	end
end
addEventHandler("onResourceStart",resourceRoot,startUp)


local allowedFunctions = { ["parseUsers"]=true, ["deleteUser"]=true, ["addUser"] = true, ["editUser"] = true }
function callServerFunction(funcname, ...)
    if not allowedFunctions[funcname] then
        outputServerLog( "SECURITY: " .. tostring(getPlayerName(client)) .. " tried to use function " .. tostring(funcname) )
        return
    end

    local arg = { ... }
    if (arg[1]) then
        for key, value in next, arg do arg[key] = tonumber(value) or value end
    end
    loadstring("return "..funcname)()(client,unpack(arg))
end
addEvent("onClientCallsServerFunction_CRUD", true)
addEventHandler("onClientCallsServerFunction_CRUD", resourceRoot , callServerFunction)

local blockTimer = nil

function isRequestBlocked(player)
	if isTimer(blockTimer) then
		_chat("Подождите немного... Слишком много запросов в единицу времени",player)
		return true
	else
		blockTimer = setTimer(function()
			blockTimer = nil;
		end,blockTime,1)
		return false
	end
end

function parseUsers(player)
	assert(player and isElement(player) and getElementType(player) == "player","wrong 1 arg(player) @parseUsers")
	if not db then
		outputDebugString(getThisResource().name.." wrong db connection: parseUsers",1)
		return false
	end
	if isRequestBlocked(player) then return end
	db:query(parseCallback,{2,"SELECT USERS",player},"SELECT * FROM ??","Users")
end

function deleteUser(player,ID)
	assert(player and isElement(player) and getElementType(player) == "player","wrong 1 arg(player) @deleteUser")
	assert(ID and type(ID) == "number","wrong 2 arg(ID) @deleteUser")
	if not db then
		outputDebugString(getThisResource().name.." wrong db connection: deleteUser",1)
		return
	end
	if isRequestBlocked(player) then return end
	db:query(parseCallback,{4,"DELETE USER",player},"DELETE FROM Users WHERE ID = ?",ID)
end

function addUser(player,Name,Surname,Adress)
	assert(player and isElement(player) and getElementType(player) == "player","wrong 1 arg(player) @addUser")
	assert(Name and type(Name) == "string","wrong 2 arg(Name) @addUser")
	assert(Surname and type(Surname) == "string","wrong 3 arg(Surname) @addUser")
	if not db then
		outputDebugString(getThisResource().name.." wrong db connection: addUser",1)
		return 
	end
	if isRequestBlocked(player) then return end
	db:query(parseCallback,{5,"ADD USER",player},"INSERT INTO Users(Name,Surname,Adress) VALUES(?,?,?)",Name,Surname,Adress)
end

function editUser(player,ID,Name,Surname,Adress)
	assert(player and isElement(player) and getElementType(player) == "player","wrong 1 arg(player) @editUser")
	assert(ID and type(ID) == "number","wrong 2 arg(ID) @editUser")
	assert(Name and type(Name) == "string","wrong 3 arg(Name) @editUser")
	assert(Surname and type(Surname) == "string","wrong 4 arg(Surname) @editUser")
	assert(Adress and type(Adress) == "string","wrong 5 arg(Adress) @editUser")
	if not db then
		outputDebugString(getThisResource().name.." wrong db connection: editUser",1)
		return
	end
	if isRequestBlocked(player) then return end
	db:query(parseCallback,{3,"EDIT USER",player},"UPDATE Users SET Name = ?, Surname = ?, Adress = ? WHERE ID = ?",Name,Surname,Adress,ID)
end

function parseCallback(qh,callbackIndex,callbackDesc,player)
	if not db then
		outputDebugString(getThisResource().name.." wrong db connection: parseCallback",1)
		return
	end
	local result = qh:poll(0)
	if result then
		if callbackIndex == 1 then --// CREATE TABLE
			outputDebugString(getThisResource().name.." Users table created!")
		elseif callbackIndex == 2 then --// SELECT
			--// Отправляем клиенту
			triggerClientEvent(player,"onRefreshPlayerInfo",player,result)
		elseif callbackIndex == 3 then --// EDIT User
			--// Отправляем клиенту
			_chat("Данные о пользователе успешно изменены",player)
			db:query(parseCallback,{2,"SELECT USERS",player},"SELECT * FROM ??","Users")
		elseif callbackIndex == 4 then --// Delete User
			--// Отправляем клиенту
			_chat("Пользователь удалён",player)
			db:query(parseCallback,{2,"SELECT USERS",player},"SELECT * FROM ??","Users")
		elseif callbackIndex == 5 then --// Add User
			--// Отправляем клиенту
			_chat("Пользователь добавлен",player)
			db:query(parseCallback,{2,"SELECT USERS",player},"SELECT * FROM ??","Users")
		end
	elseif result == nil then
		qh:free()
	else
		outputDebugString("db callback: ошибка запроса, callbackInfo{ID:"..callbackIndex.."; Desc:"..callbackDesc.."}",1)
	end
end

_chat = function(message,player)
	outputChatBox("#00FFDE[CRUD]#FFFFFF "..message,player,255,255,255,true)
end