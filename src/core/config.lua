local config = {}

config.red_wire_name = 'red'
config.green_wire_name = 'green'
function config.get_wire_label(k) return config[k..'_wire_name'] end


-- Interval between raising global alerts on lua errors, in ticks
config.logic_alert_interval = 10 * 60

-- Thresholds for LED state indication
config.led_sleep_min = 5 * 60 -- avoids flipping between sleep/run too often

-- entity.energy threshold when combinator shuts down
-- Full e-buffer of arithmetic combinator is 34.44, "red" level in UI is half of it
config.energy_fail_level = 34.44 / 2
config.energy_fail_delay = 2 * 60 -- when to re-check energy level


return config
