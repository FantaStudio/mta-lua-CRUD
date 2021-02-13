dbConfig = { --// Database configuration
    ["host"] = "127.0.0.1", --// Database adress
    ["username"] = "root", --// Database username
    ["password"] = "root", --// Database user password
    ["dbname"] = "test", --// Database name
    --["port"] = "", --// Database port
    --["unix_socket"] = "",
    --["charset"] = "", --// Database charset
}

toggledKey = "L" --// Open/close button
blockTime = 5000 --// Request block time in ms

function isEventHandlerAdded( sEventName, pElementAttachedTo, func )
    if type( sEventName ) == 'string' and isElement( pElementAttachedTo ) and type( func ) == 'function' then
        local aAttachedFunctions = getEventHandlers( sEventName, pElementAttachedTo )
        if type( aAttachedFunctions ) == 'table' and #aAttachedFunctions > 0 then
            for i, v in ipairs( aAttachedFunctions ) do
                if v == func then
                    return true
                end
            end
        end
    end
    return false
end
