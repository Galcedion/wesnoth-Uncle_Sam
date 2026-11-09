--<<
_ = wesnoth.textdomain "wesnoth-Uncle_Sam"

local on_event = wesnoth.require("lua/on_event.lua")

local us_startingcash = wesnoth.get_variable("us_startingcash")
local us_cashrate = wesnoth.get_variable("us_cashrate")
local us_rates = wesnoth.get_variable("us_rates")
local schedule_length = 1

function us_grant_cash()
	wesnoth.fire("gold",{
		amount = us_cashrate
	})
	wesnoth.message("", _ "Uncle Sam granted everyone $us_cashrate| gold") -- passing var seemingly doesnt work here
	wesnoth.fire("message",{
		message = _ "Uncle Sam granted everyone $us_cashrate| gold",
		speaker = "narrator"
	})
	-- TODO either of those messages should suffice, but the latter is only displayed once, which is an issue for multiple sides controlled by the same player
end

on_event("prestart", function()
	-- get day schedule length
	local cur_day = wml.variables.turn_number
	wesnoth.fire("store_time_of_day", {
		turn = cur_day
	})
	local schedule_reference = wml.variables.time_of_day.id
	while cur_day <= 100 do
		cur_day = cur_day + 1
		wesnoth.fire("store_time_of_day", {
			turn = cur_day
		})
		if wml.variables.time_of_day.id == schedule_reference then
			break
		end
		schedule_length = schedule_length + 1
	end
	-- set initial gold
	for s=1, #wesnoth.sides do
		wesnoth.fire("store_gold",{
			side = s
		})
		wesnoth.fire("gold",{
			side = s,
			amount = -wml.variables.gold
		})
		-- wesnoth.sides[s].gold = 0 | alternative to fire negative gold
		wesnoth.sides[s].base_income = 0
		wesnoth.sides[s].village_gold = 0
	end
	wesnoth.fire("gold",{
		amount = us_startingcash
	})
end)

on_event("turn end", function()
	if us_rates == 0.5 then
		if wesnoth.current.turn % schedule_length == 0 then
			us_grant_cash()
		elseif wesnoth.current.turn % math.floor(schedule_length / 2) == 0 then
			us_grant_cash()
		end
	elseif wesnoth.current.turn % (schedule_length * us_rates) == 0 then
		us_grant_cash()
	end
end)
-->>