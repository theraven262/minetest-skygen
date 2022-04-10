-- Dont forget to set cloud radius to 26 in minetest's settings

skygen = {}
skygen.start = 1 -- For first time run

skygen.biome_names = {
    "cold_desert",
    "cold_desert_under",
    "cold_desert_ocean",
    "desert",
    "desert_ocean",
    "desert_under",
    "taiga",
    "taiga_ocean",
    "taiga_under",
    "snowy_grassland",
    "snowy_grassland_under",
    "snowy_grassland_ocean",
    "grassland",
    "grassland_ocean",
    "grassland_dunes",
    "grassland_under",
    "coniferous_forest",
    "coniferous_forest_dunes",
    "coniferous_forest_ocean",
    "coniferous_forest_under",
    "deciduous_forest",
    "deciduous_forest_ocean",
    "deciduous_forest_under",
    "deciduous_forest_shore",
    "rainforest",
    "rainforest_ocean",
    "rainforest_swamp",
    "rainforest_under",
    "icesheet",
    "icesheet_ocean",
    "icesheet_under",
    "tundra",
    "tundra_highland",
    "tundra_beach",
    "tundra_ocean",
    "tundra_under",
    "sandstone_desert",
    "sandstone_desert_ocean",
    "sandstone_desert_under",
    "savanna",
    "savanna_shore",
    "savanna_ocean",
    "savanna_under"
}

local path = minetest.get_modpath("skygen")
dofile(path.."/colors.lua")

skygen.transition_state = {}
skygen.previous_biome = {}

skygen.transition_frames = 16

skygen.set_sky = function(player, biome_name)

    local base_values = skygen.biomes[biome_name].colors

    player:set_sky({
        type = "regular",
        sky_color = {
            day_sky         = {r = base_values[1][1],   g = base_values[1][2],  b = base_values[1][3]},
            day_horizon     = {r = base_values[2][1],   g = base_values[2][2],  b = base_values[2][3]},
            dawn_sky        = {r = base_values[5][1],   g = base_values[5][2],  b = base_values[5][3]}, -- base_values[5] to base_values[8] are calculated
            dawn_horizon    = {r = base_values[6][1],   g = base_values[6][2],  b = base_values[6][3]},
            night_sky       = {r = base_values[7][1],   g = base_values[7][2],  b = base_values[7][3]},
            night_horizon   = {r = base_values[8][1],   g = base_values[8][2],  b = base_values[8][3]},
            indoors         = {r = 128,                 g = 128,                b = 128}, -- Don't see much point in changing this
            fog_sun_tint    = {r = base_values[3][1],   g = base_values[3][2],  b = base_values[3][3]},
            fog_moon_tint   = {r = base_values[4][1],   g = base_values[4][2],  b = base_values[4][3]},
            fog_tint_type = "custom"
        }
    })

end

skygen.init_transition = function(player, prev_biome_name, biome_name)

    skygen.transition_state[player:get_player_name()] = true

    local base_colors = {}
    base_colors[1] = skygen.biomes[prev_biome_name].colors[3] -- Sun tint
    base_colors[2] = skygen.biomes[prev_biome_name].colors[4] -- Moon tint

    local base_params = {}
    base_params[1] = minetest.registered_biomes[prev_biome_name].heat_point
    base_params[2] = minetest.registered_biomes[prev_biome_name].humidity_point

    local color_diffs = skygen.get_color_diffs(prev_biome_name, biome_name)
    local param_diffs = skygen.get_param_diffs(prev_biome_name, biome_name)

    skygen.transition(player, base_colors, base_params, color_diffs, param_diffs, 0, biome_name)

end

skygen.transition = function(player, base_colors, base_params, color_diffs, param_diffs, progress, biome)

    if progress == skygen.transition_frames then

        skygen.transition_state[player:get_player_name()] = false
        skygen.previous_biome[player:get_player_name()] = biome

    else

        progress = progress + 1

        base_params[1] = base_params[1] + param_diffs[1]
        base_params[2] = base_params[2] + param_diffs[2]

        local heat = base_params[1]*2.55 -- 0 ... 255
        local humidity = base_params[2]/100 -- 0 ... 1

        for k=1,2 do

            for i=1,3 do 

                base_colors[k][i] = base_colors[k][i] + color_diffs[k][i]

            end

        end

        local sun = base_colors[1]
        local moon = base_colors[2]

        player:set_clouds({
            density = humidity/1.5,
            color = {r = 255, g =  255, b =  255, a = 255 * humidity},
            thickness = humidity * 80
        })
    
        player:set_sun({
            scale = ((heat/255) + 0.1)*2
        })
    
        player:set_moon({
            scale = ((heat/255) + 0.1)*4
        })
    
        player:set_stars({
            star_color = {r = sun[1], g = sun[2], b = sun[3]},
            count = (1.5 - humidity) * 4 * 10
        })

        minetest.after(1 / skygen.transition_frames, function()
            skygen.transition(player, base_colors, base_params, color_diffs, param_diffs, progress, biome)
        end)

    end

end

skygen.colorize = function(color, colorizer, amount)

    local result = {}
    local difference = 0

    for i=1,3 do

        difference = colorizer[i] - color[i]
        result[i] = color[i] + (difference * amount)

    end

    return result

end

skygen.set_all = function(player, biome_name) -- For initial case

    sun = skygen.biomes[biome_name].colors[3] -- Sun tint
    moon = skygen.biomes[biome_name].colors[4] -- Moon tint

    heat = minetest.registered_biomes[biome_name].heat_point*2.55
    humidity = minetest.registered_biomes[biome_name].humidity_point/100

    player:set_clouds({
        density = humidity/1.5,
        color = {r = 255, g =  255, b =  255, a = 255 * humidity},
        thickness = humidity * 80
    })

    player:set_sun({
        scale = ((heat/255) + 0.1)*2
    })

    player:set_moon({
        scale = ((heat/255) + 0.1)*4
    })

    player:set_stars({
        star_color = {r = sun[1], g = sun[2], b = sun[3]},
        count = (1.5 - humidity) * 4 * 10
    })

end

skygen.set_clouds = function(player, biome_name) -- Cause minetest sets them to default every now and then

    local heat = minetest.registered_biomes[biome_name].heat_point*2.55
    local humidity = minetest.registered_biomes[biome_name].humidity_point/100

    player:set_clouds({
        density = humidity/1.5,
        color = {r = 255, g =  255, b =  255, a = 255 * humidity},
        thickness = humidity * 80
    })

end

skygen.get_param_diffs = function(prev_biome_name, biome_name)

    local prev_heat = minetest.registered_biomes[prev_biome_name].heat_point
    local prev_humidity = minetest.registered_biomes[prev_biome_name].humidity_point

    local heat = minetest.registered_biomes[biome_name].heat_point
    local humidity = minetest.registered_biomes[biome_name].humidity_point

    local results = {}

    results[1] = (heat - prev_heat) / skygen.transition_frames
    results[2] = (humidity - prev_humidity) / skygen.transition_frames

    return results

end

skygen.get_color_diffs = function(prev_biome_name, biome_name)

    local prev_colorset = {}
    prev_colorset[1] = skygen.biomes[prev_biome_name].colors[3] -- Sun tint
    prev_colorset[2] = skygen.biomes[prev_biome_name].colors[4] -- Moon tint

    local colorset = {}
    colorset[1] = skygen.biomes[biome_name].colors[3] -- Sun tint
    colorset[2] = skygen.biomes[biome_name].colors[4] -- Moon tint

    local result = {{}, {}}

    for k=1,2 do

        for i=1,3 do

            result[k][i] = (colorset[k][i] - prev_colorset[k][i]) / skygen.transition_frames

        end

    end

    return result

end

skygen.fetch_biome = function(player)

    local player_pos = player:get_pos()
    local biome_data = minetest.get_biome_data(player_pos)

    local biome = minetest.get_biome_name(biome_data.biome)
    local heat = biome_data.heat*2.55 -- 0 ... 255
    local humidity = biome_data.humidity/100 -- 0 ... 1

    local values = {}

    values[1] = biome
    values[2] = heat
    values[3] = humidity

    return values

end

minetest.register_globalstep(function(dtime)

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

    else

        for i=1, #players do

            local player = players[i]
            local player_name = player:get_player_name()
            local biome_data = skygen.fetch_biome(player)
            local biome_name = biome_data[1]
            local previous_biome_name = skygen.previous_biome[player_name]

            if skygen.transition_state[player_name] == nil then

                skygen.transition_state[player_name] = false

            end

            if skygen.transition_state[player_name] == true then

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

end)