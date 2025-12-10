-- Utility module for parsing and formatting Lua literal values in test case variables
--
-- Usage examples:
--   value_parser.format_value(42)              -> "42"
--   value_parser.format_value({1, 2, 3})       -> "[1, 2, 3]"
--   value_parser.format_value({a=1, b=2})      -> "{a = 1, b = 2}"
--
--   value_parser.parse_value("42")             -> true, 42
--   value_parser.parse_value("[1, 2, 3]")      -> true, {1, 2, 3}
--   value_parser.parse_value("{a=1, b=2}")     -> true, {a=1, b=2}
--
local value_parser = {}

-- Format a value for display (converts to string representation)
function value_parser.format_value(value)
    if value == nil then
        return "nil"
    elseif type(value) == "number" then
        return tostring(value)
    elseif type(value) == "string" then
        return '"' .. value:gsub('"', '\\"') .. '"'
    elseif type(value) == "boolean" then
        return tostring(value)
    elseif type(value) == "table" then
        -- Format table as array [1, 2, 3] or object {key=value}
        local is_array = true
        local max_index = 0
        local count = 0

        for k, _ in pairs(value) do
            count = count + 1
            if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
                is_array = false
                break
            end
            if k > max_index then
                max_index = k
            end
        end

        -- Check if it's a contiguous array
        if is_array and max_index == count and count > 0 then
            local parts = {}
            for i = 1, max_index do
                table.insert(parts, value_parser.format_value(value[i]))
            end
            return "[" .. table.concat(parts, ", ") .. "]"
        else
            -- Format as object
            local parts = {}
            for k, v in pairs(value) do
                local key_str = type(k) == "string" and k or "[" .. tostring(k) .. "]"
                table.insert(parts, key_str .. " = " .. value_parser.format_value(v))
            end
            return "{" .. table.concat(parts, ", ") .. "}"
        end
    else
        return tostring(value)
    end
end

-- Parse a string as a Lua literal value
-- Returns: success (boolean), value (parsed value or error message)
function value_parser.parse_value(str)
    if not str or str == "" then
        return false, "Empty input"
    end

    -- Trim whitespace
    str = str:match("^%s*(.-)%s*$")

    -- Try to parse as number first
    local num = tonumber(str)
    if num then
        return true, num
    end

    -- Check for boolean
    if str == "true" then
        return true, true
    elseif str == "false" then
        return true, false
    elseif str == "nil" then
        return true, nil
    end

    -- Check for string literal
    if (str:sub(1, 1) == '"' and str:sub(-1) == '"') or (str:sub(1, 1) == "'" and str:sub(-1) == "'") then
        local inner = str:sub(2, -2)
        -- Unescape basic escape sequences
        inner = inner:gsub('\\"', '"'):gsub("\\'", "'")
        return true, inner
    end

    -- Check for array literal [1, 2, 3]
    if str:sub(1, 1) == "[" and str:sub(-1) == "]" then
        local inner = str:sub(2, -2):match("^%s*(.-)%s*$")
        if inner == "" then
            return true, {}
        end

        local result = {}
        local depth = 0
        local current = ""

        for i = 1, #inner do
            local char = inner:sub(i, i)
            if char == "[" or char == "{" then
                depth = depth + 1
                current = current .. char
            elseif char == "]" or char == "}" then
                depth = depth - 1
                current = current .. char
            elseif char == "," and depth == 0 then
                -- Found a separator at top level
                local success, value = value_parser.parse_value(current)
                if not success then
                    return false, "Invalid element: " .. current
                end
                table.insert(result, value)
                current = ""
            else
                current = current .. char
            end
        end

        -- Parse last element
        current = current:match("^%s*(.-)%s*$")
        if current ~= "" then
            local success, value = value_parser.parse_value(current)
            if not success then
                return false, "Invalid element: " .. current
            end
            table.insert(result, value)
        end

        return true, result
    end

    -- Check for table literal {key=value, ...} or {key: value, ...}
    if str:sub(1, 1) == "{" and str:sub(-1) == "}" then
        local inner = str:sub(2, -2):match("^%s*(.-)%s*$")
        if inner == "" then
            return true, {}
        end

        local result = {}
        local depth = 0
        local current = ""

        for i = 1, #inner do
            local char = inner:sub(i, i)
            if char == "[" or char == "{" then
                depth = depth + 1
                current = current .. char
            elseif char == "]" or char == "}" then
                depth = depth - 1
                current = current .. char
            elseif char == "," and depth == 0 then
                -- Found a separator at top level
                local key, value = current:match("^%s*([^=:]+)%s*[=:]%s*(.+)%s*$")
                if not key then
                    return false, "Invalid entry: " .. current
                end

                -- Parse key
                key = key:match("^%s*(.-)%s*$")
                local parsed_key
                if key:sub(1, 1) == "[" and key:sub(-1) == "]" then
                    local success_key, temp_key = value_parser.parse_value(key:sub(2, -2))
                    if not success_key then
                        return false, "Invalid key: " .. key
                    end
                    parsed_key = temp_key
                else
                    -- Try as identifier or number
                    parsed_key = tonumber(key) or key
                end

                -- Parse value
                local success_val, parsed_val = value_parser.parse_value(value)
                if not success_val then
                    return false, "Invalid value: " .. value
                end

                if parsed_key ~= nil then
                    result[parsed_key] = parsed_val
                end
                current = ""
            else
                current = current .. char
            end
        end

        -- Parse last entry
        current = current:match("^%s*(.-)%s*$")
        if current ~= "" then
            local key, value = current:match("^%s*([^=:]+)%s*[=:]%s*(.+)%s*$")
            if not key then
                return false, "Invalid entry: " .. current
            end

            key = key:match("^%s*(.-)%s*$")
            local parsed_key
            if key:sub(1, 1) == "[" and key:sub(-1) == "]" then
                local success_key, temp_key = value_parser.parse_value(key:sub(2, -2))
                if not success_key then
                    return false, "Invalid key: " .. key
                end
                parsed_key = temp_key
            else
                parsed_key = tonumber(key) or key
            end

            local success_val, parsed_val = value_parser.parse_value(value)
            if not success_val then
                return false, "Invalid value: " .. value
            end

            if parsed_key ~= nil then
                result[parsed_key] = parsed_val
            end
        end

        return true, result
    end

    -- If nothing matched, treat as identifier/string
    -- For safety, only accept valid identifiers
    if str:match("^[%a_][%w_]*$") then
        return true, str
    end

    return false, "Invalid literal"
end

return value_parser
