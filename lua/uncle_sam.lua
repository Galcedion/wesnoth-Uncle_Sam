--<<
_ = wesnoth.textdomain "wesnoth-Uncle_Sam"

local on_event = wesnoth.require("lua/on_event.lua")

local us_startingcash = wesnoth.get_variable("us_startingcash")
local us_cashrate = wesnoth.get_variable("us_cashrate")
local us_rates = wesnoth.get_variable("us_rates")
local us_unitlimit = wesnoth.get_variable("us_unitlimit")
local us_messages = wesnoth.get_variable("us_messages")
local schedule_length = 1
local stored_message = ""
local stored_recruit = {}
local emptied_recruit = {}

function us_grant_cash()
	wesnoth.fire("gold",{
		amount = us_cashrate
	})
	if us_messages == 1 then
		wesnoth.message(_ "Uncle Sam", _ "granted everyone some cash")
	elseif us_messages == 2 then
		stored_message = _ "Uncle Sam granted everyone $us_cashrate| cash."
	end
end

function calculate_budget()
	if us_unitlimit == 0 then
		return
	end
	local budget = us_unitlimit
	local cur_side = wesnoth.current.side
	local u_store = wesnoth.units.find_on_map({side = cur_side})
	for k, v in ipairs(u_store) do
		budget = budget - v["cost"]
	end
	if budget <= 0 and emptied_recruit[cur_side] == nil then
		wesnoth.fire("set_recruit",{
			recruit = {},
			side = cur_side
		})
		emptied_recruit[cur_side] = 1
	elseif budget >= 0 and emptied_recruit[cur_side] ~= nil then
		wesnoth.fire("set_recruit",{
			recruit = stored_recruit[cur_side],
			side = cur_side
		})
		emptied_recruit[cur_side] = nil
	end
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
	-- set initial gold and save recruit lists
	for s=1, #wesnoth.sides do
		wesnoth.sides[s].gold = us_startingcash
		wesnoth.sides[s].base_income = 0
		wesnoth.sides[s].village_gold = 0
		wesnoth.sides[s].village_support = 0
		stored_recruit[s] = wesnoth.sides[s].recruit
	end
	if us_messages == 1 then
		wesnoth.message(_ "Uncle Sam", _ "gave everyone some starting money")
	elseif us_messages == 2 then
		stored_message = _ "Uncle Sam gave everyone $us_cashrate| starting money."
	end
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

on_event("new turn", function()
	if stored_message ~= "" then
		wesnoth.fire("message",{
			message = stored_message,
			speaker = "narrator"
		})
		stored_message = ""
	end
end)

on_event("side turn", function()
	calculate_budget()
end)

on_event("post advance", function()
	calculate_budget()
end)

on_event("recruit", function()
	calculate_budget()
end)
-->>