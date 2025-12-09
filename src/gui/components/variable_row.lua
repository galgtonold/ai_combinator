local variable_row = {}

function variable_row.show(table, uid, test_index, row_index, name, value)
    -- Variable name input
    local name_input = table.add({
        type = "textfield",
        text = name,
        name = "var-name-" .. row_index,
        tags = { uid = uid, test_index = test_index, var_row = row_index, var_name_input = true },
    })
    name_input.style.width = 150

    -- Variable value input
    local value_input = table.add({
        type = "textfield",
        text = tostring(value),
        numeric = true,
        allow_negative = true,
        name = "var-value-" .. row_index,
        tags = { uid = uid, test_index = test_index, var_row = row_index, var_value_input = true },
    })
    value_input.style.width = 100

    -- Delete button (only show for non-empty rows)
    local delete_btn = table.add({
        type = "sprite-button",
        sprite = "utility/trash",
        name = "var-delete-" .. row_index,
        style = "tool_button_red",
        tooltip = "Delete variable",
        tags = { uid = uid, test_index = test_index, var_row = row_index, delete_variable = true },
    })
    delete_btn.style.width = 24
    delete_btn.style.height = 24
    delete_btn.visible = name ~= "" or value ~= 0
end

return variable_row
