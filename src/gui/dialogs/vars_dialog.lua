local dialog = {}

function dialog.show(pn, uid, paused, toggle_on)
    -- Switches variables-window to specified combinator or toggles it on/off
    local player, gui_k = game.players[pn], "vars." .. pn
    local gui_exists = player.gui.screen["ai-combinator-vars"]
    if gui_exists then
        if toggle_on or (toggle_on == nil and storage.guis_player[gui_k] ~= uid) then
            storage.guis_player[gui_k] = uid
            return dialog.update(player, uid, paused)
        elseif not toggle_on then
            return gui_exists.destroy()
        end
    elseif toggle_on == false then
        return
    end -- force off toggle

    local dw, dh, dsf = player.display_resolution.width, player.display_resolution.height, 1 / player.display_scale
    storage.guis_player[gui_k] = uid
    local gui = player.gui.screen.add({ type = "frame", name = "ai-combinator-vars", caption = "", direction = "vertical" })
    gui.location = { math.max(50, (dw - 800) * dsf), 45 * dsf }
    local scroll = gui.add({ type = "scroll-pane", name = "ai-combinator-vars-scroll", direction = "vertical" })
    scroll.style.maximal_height = (dh - 300) * dsf
    local tb = scroll.add({ type = "text-box", name = "ai-combinator-vars-box", text = "" })
    tb.style.width = 500
    tb.read_only, tb.selectable, tb.word_wrap = true, false, true
    local btns = gui.add({ type = "flow", name = "ai-combinator-vars-btns", direction = "horizontal" })
    btns.add({ type = "button", name = "ai-combinator-vars-close", caption = "Close" })
    btns.add({
        type = "button",
        name = "ai-combinator-vars-pause",
        caption = "Pause",
        tooltip = "Pausing updates also makes text editable,"
            .. " so that Ctrl-A/Ctrl-C can be used there, but editing it will not change the environment.",
    })
    dialog.update(player, uid, paused)
end

function dialog.update(player, uid, pause_update)
    local gui = player.gui.screen["ai-combinator-vars"]
    if not gui then
        return
    end
    local gui_paused = gui.caption:match(" %-%- .+$")
    if pause_update ~= nil then
        gui_paused = pause_update
    end -- explicit pause/unpause
    if gui_paused and pause_update == nil then
        return
    end -- ignore calls from combinator updates
    local gui_st_old, gui_st = gui.caption, ("AI Combinator Environment Variables [%s]%s"):format(uid, gui_paused and " -- PAUSED" or "")
    if gui_st ~= gui_st_old then
        gui.caption, gui_st = gui_st, gui.children[2].children[2]
        gui_st.style = gui_paused and "green_button" or "button"
        gui_st.caption = gui_paused and "Unpause" or "Pause"
    end
    local combinator, vars_box = storage.combinators[uid], gui["ai-combinator-vars-scroll"]["ai-combinator-vars-box"]
    if gui_paused and vars_box.read_only then
        vars_box.selectable, vars_box.read_only = true, false
        vars_box.tooltip = "Text is editable for selection/copying while paused,\n" .. "but changing it will not update the environment."
    elseif not gui_paused and not vars_box.read_only then
        vars_box.selectable, vars_box.read_only, vars_box.tooltip = false, true, ""
    end

    if not combinator then
        vars_box.text = "--- [color=#911818]AI Combinator is Offline[/color] ---"
    else
        local text, esc, vs = "", function(s)
            return tostring(s):gsub("%[", "[ ")
        end, nil
        local gui_vars_serpent_opts = { metatostring = true, nocode = true }
        for k, v in pairs(combinator.vars) do
            if k:match("^__") then
                goto skip
            end
            if text ~= "" then
                text = text .. "\n"
            end
            vs = serpent.line(v, gui_vars_serpent_opts)
            if vs:len() > 80 then
                vs = serpent.block(v, gui_vars_serpent_opts)
            elseif vs:len() > 80 * 0.6 then
                vs = "\n  " .. vs
            end
            text = text .. ("[color=#520007][font=default-bold]%s[/font][/color] = %s"):format(esc(k), esc(vs))
            ::skip::
        end
        vars_box.text = text
    end
end

return dialog
