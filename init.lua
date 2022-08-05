-- Dont forget to set cloud radius to 26 in minetest's settings

skygen = {}
skygen.start = 1
skygen.save_timer = 0
skygen.save_interval = 1000
skygen.sky_state = {}
skygen.active = true

skygen.skybox_names = {"test_sky"} -- Add skybox names here
skygen.skyboxes = {}
skygen.save_file = minetest.get_worldpath() .. "/skygen"

skygen.colorize_stars = true

local path = minetest.get_modpath("skygen")
local skybox_path = minetest.get_modpath("skygen") .. "/skyboxes"
dofile(path.."/colors.lua")
dofile(path.."/biome.lua")
dofile(path.."/skybox.lua")

for i=1,#skygen.skybox_names do
    dofile(skybox_path .. "/" .. skygen.skybox_names[i] .. "/skydef.lua")
end

function skygen.load_saves()
	local input = io.open(skygen.save_file, "r")
	if not input then
		return
	end
	-- Iterate over all recorded states in the format "player state skybox" for each line
	for name, state, skybox in input:read("*a"):gmatch("([%w_-]+)%s([%w_-]+)%s([%w_-]+)[\r\n]") do
        if state == "skybox" then
            state = "skybox_reset"
        elseif state == "inactive" then
            state = "inactive_reset"
        end
		skygen.sky_state[name] = state
        skygen.skybox_status[name] = skybox
	end
    print(dump(skygen.sky_state))
	input:close()
end

function skygen.save()
    local data = {}
    local output = io.open(skygen.save_file, "w")
    if output then
        local s = ""
        for i, v in pairs(skygen.sky_state) do
            s = skygen.skybox_status[i]
            if not s then
                s = "none"
            end
            table.insert(data, string.format("%s %s %s\n", i, v, s))
        end
        output:write(table.concat(data))
        io.close(output)
        return true
    end
    return true
end

skygen.load_saves()
minetest.register_on_shutdown(function()
    skygen.save()
end)

minetest.register_on_leaveplayer(function(player)
    if skygen.sky_state[player:get_player_name()] == "skybox" then
        skygen.sky_state[player:get_player_name()] = "skybox_reset"
    elseif skygen.sky_state[player:get_player_name()] == "skybox" then
        skygen.sky_state[player:get_player_name()] = "inactive_reset"
    end
end)

skygen.sky_globalstep = function(players)
    for i=1, #players do
        local player = players[i]
        local player_name = player:get_player_name()
        if (skygen.sky_state[player_name] == "skybox_reset") then -- Player has reconnected in the meantime and the skybox has to be set anew
            skygen.set_skybox(player, skygen.skybox_status[player:get_player_name()])
        elseif (skygen.sky_state[player_name] == "inactive_reset") then
            skygen.deactivate()
        elseif (skygen.sky_state[player_name] == "skybox") or (skygen.sky_state[player_name] == "inactive") then
        else
            local biome_data = skygen.fetch_biome(player)
            local biome_name = biome_data[1]
            local previous_biome_name = skygen.previous_biome[player_name]
            if (skygen.sky_state[player_name] == nil) then
                skygen.sky_state[player_name] = "biome"
            end
            if skygen.sky_state[player_name] == "transition" then
            elseif biome_name == previous_biome_name then
                skygen.set_clouds(player, biome_name) -- Cause minetest resets them every now and then
            elseif previous_biome_name == nil then
                skygen.previous_biome[player_name] = biome_name
                skygen.set_sky(player, biome_name)
                skygen.set_all(player, biome_name)
            else
                --minetest.chat_send_player(player_name, "Change Init: " .. previous_biome_name .. " to " .. biome_name) -- Debug
                skygen.set_sky(player, biome_name)
                skygen.init_transition(player, previous_biome_name, biome_name)
            end
        end
    end
end

minetest.register_globalstep(function()
    local players = minetest.get_connected_players()
    if skygen.start == 1 then -- Build the virtual table
        skygen.start = 0
        for i=1, #skygen.biome_names do
            local biome_name = skygen.biome_names[i]
            local biome_colors = skygen.biomes[biome_name].colors
            biome_colors[5] = skygen.colorize(biome_colors[2], biome_colors[3], 0.75) -- Dawn
            biome_colors[6] = skygen.colorize(biome_colors[1], biome_colors[3], 0.75) -- Dawn Horizon
            biome_colors[7] = skygen.colorize(biome_colors[1], biome_colors[4], 0.75) -- Night
            biome_colors[8] = skygen.colorize(biome_colors[2], biome_colors[4], 0.75) -- Night Horizon
        end
        skygen.sky_globalstep(players)
    else
        skygen.sky_globalstep(players)
        if (skygen.save_timer > skygen.save_interval) then
            skygen.save()
            skygen.save_timer = 0
        else
            skygen.save_timer = skygen.save_timer + 1
        end
    end
end)

skygen.deactivate = function(player)
    skygen.sky_state[player] = "inactive"
    local player_obj = minetest.get_player_by_name(player)
    player_obj:set_sky()
    player_obj:set_sun()
    player_obj:set_stars()
    player_obj:set_moon()
    player_obj:set_clouds()
    player_obj:override_day_night_ratio(nil)
end

minetest.register_chatcommand("skygen", {
    params = "<state> <skybox>",
    description = "SkyGen settings; \"off\" to disable; \"biome\" for default; \"skybox skybox_name\" for skybox mode",
    func = function(name, param)
        local parameters = {}
        local p = 1
        for iterator in param:gmatch("%g+") do
            parameters[p] = iterator
            p = p + 1
        end
        if parameters[1] == "off" then
            skygen.deactivate(name)
            minetest.chat_send_player("The sky is now set to be Minetest default")
        elseif parameters[1] == "biome" then
            skygen.biome_mode(name)
            minetest.chat_send_player("The sky is now set to be biome-adaptive")
        elseif parameters[1] == "skybox" then
            for i=1, #skygen.skybox_names do
                if skygen.skybox_names[i] == parameters[2] then
                    local sky_description = skygen.skyboxes[parameters[2]].description
                    skygen.set_skybox(minetest.get_player_by_name(name), parameters[2])
                    minetest.chat_send_player("The sky is now set to be a skybox, " .. sky_description)
                end
            end
        end
    end
})