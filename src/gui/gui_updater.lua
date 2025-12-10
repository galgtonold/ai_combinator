local circuit_network = require("src/core/circuit_network")
local constants = require("src/core/constants")
local util = require("src/core/utils")
local memory = require("src/ai_combinator/memory")
local init = require("src/ai_combinator/init")

local gui_updater = {}

local function signal_icon_tag(sig)
    local sig = storage.signals[sig]
    if not sig then
        return ""
    end
    if sig.type == "virtual" then
        return "[virtual-signal=" .. sig.name .. "] "
    end
    if sig.type == nil then
        return ""
    end
    if helpers.is_valid_sprite_path(sig.type .. "/" .. sig.name) then
        return "[img=" .. sig.type .. "/" .. sig.name .. "] "
    end
end

local function quality_icon_tag(qname)
    if not qname then
        return ""
    end
    if helpers.is_valid_sprite_path("quality/" .. qname) then
        return "[img=quality/" .. qname .. "]"
    end
end

function gui_updater.update_signals_in_guis(format_error_message)
    local gui_flow, label, combinator, cb, sig, combinator_out, combinator_out_idx, combinator_out_err
    local colors = { red = { 1, 0.3, 0.3 }, green = { 0.3, 1, 0.3 } }
    for uid, gui_t in pairs(storage.guis) do
        combinator = storage.combinators[uid]
        if not (combinator and combinator.e.valid) then
            init.combinator_remove(uid)
            goto skip
        end
        gui_flow = gui_t.signal_pane
        if not (gui_flow and gui_flow.valid) then
            goto skip
        end
        gui_flow.clear()

        -- Inputs
        for k, color in pairs(colors) do
            cb = circuit_network.cn_wire_signals(combinator.e, defines.wire_type[k])
            for sig, v in pairs(cb) do
                if v == 0 then
                    goto skip
                end
                if not sig then
                    goto skip
                end
                local signame, qname = circuit_network.cn_sig_quality(sig)
                local icon = signal_icon_tag(circuit_network.cn_sig_str(signame))
                if qname then
                    icon = quality_icon_tag(qname) .. icon
                end
                label = gui_flow.add({
                    type = "label",
                    name = "ai-combinator-sig-in-" .. k .. "-" .. sig,
                    caption = ("[%s] %s%s = %s"):format(constants.get_wire_label(k), icon, sig, v),
                })
                label.style.font_color = color
                label.tags = { signal = sig }
                ::skip::
            end
        end

        -- Outputs
        combinator_out, combinator_out_idx, combinator_out_err = {}, {}, util.shallow_copy((memory.combinators[uid] or {})._out or {}) or {}
        for k, cb in pairs({ red = combinator.out_red, green = combinator.out_green }) do
            cb = cb.get_control_behavior()
            for _, cbs in pairs(cb.sections[1].filters or {}) do
                sig, label = cbs.value.name, constants.get_wire_label(k)
                if not sig then
                    goto cb_slots_end
                end
                if cbs.value.quality ~= nil and cbs.value.quality ~= "normal" then
                    sig = cbs.value.quality .. "/" .. sig
                end
                if combinator_out_err then
                    ---@diagnostic disable-next-line: need-check-nil
                    combinator_out_err[sig], combinator_out_err[("%s/%s"):format(k, sig)] = nil, nil
                    ---@diagnostic disable-next-line: need-check-nil
                    combinator_out_err[("%s/%s"):format(label, sig)] = nil
                end
                sig = circuit_network.cn_sig_str(cbs.value)
                if combinator_out_err then
                    ---@diagnostic disable-next-line: need-check-nil
                    combinator_out_err[sig], combinator_out_err[("%s/%s"):format(k, sig)] = nil, nil
                    ---@diagnostic disable-next-line: need-check-nil
                    combinator_out_err[("%s/%s"):format(label, sig)] = nil
                end
                if cbs.min ~= 0 then
                    if not combinator_out[sig] then
                        ---@diagnostic disable-next-line: need-check-nil
                        combinator_out_idx[#combinator_out_idx + 1], combinator_out[sig] = sig, {}
                    end
                    combinator_out[sig][k] = cbs.min
                end
            end
            ::cb_slots_end::
        end
        table.sort(combinator_out_idx)
        for val, k in pairs(combinator_out_idx) do
            local signame, qname = circuit_network.cn_sig_quality(k)
            if signame then
                val, sig, label = combinator_out[k], storage.signals[signame].name, signal_icon_tag(signame)
                if string.sub(signame, 1, 1) == "~" then
                    sig = "~" .. sig
                end
                if qname then
                    label = quality_icon_tag(qname) .. label
                    sig = qname .. "/" .. sig
                end
                if val["red"] == val["green"] then
                    k = gui_flow.add({
                        type = "label",
                        name = "ai-combinator-sig-out-" .. sig,
                        caption = ("[out] %s%s = %s"):format(label, sig, val["red"] or 0),
                    })
                    k.tags = { signal = sig }
                else
                    for k, color in pairs(colors) do
                        k = gui_flow.add({
                            type = "label",
                            name = "ai-combinator-sig-out/" .. k .. "-" .. sig,
                            caption = ("[out/%s] %s%s = %s"):format(constants.get_wire_label(k), label, sig, val[k] or 0),
                        })
                        k.style.font_color = color
                        k.tags = { signal = sig }
                    end
                end
            end
        end

        -- Remaining invalid signals and errors
        local n = 0 -- to dedup bogus non-string signal keys that have same string repr
        if combinator_out_err then
            for sig, val in pairs(combinator_out_err) do
                cb, val = pcall(serpent.line, val, { compact = true, nohuge = false })
                if not cb then
                    val = "<err>"
                end
                if val:len() > 8 then
                    val = val:sub(1, 8) .. "+"
                end
                gui_flow.add({
                    type = "label",
                    name = ("ai-combinator-sig-out/err-%d-%s"):format(n, sig),
                    caption = ("[color=#ce9f7f][out-invalid] %s = %s[/color]"):format(sig, val),
                })
                n = n + 1
            end
        end
        gui_t.errors.caption = format_error_message(combinator) or ""
        ::skip::
    end
end

return gui_updater
