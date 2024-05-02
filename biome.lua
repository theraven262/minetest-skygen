function skygen.set_biome_sky(player, biome_name)
    skygen.set_sky_colors(player, biome_name)
    local name = player:get_player_name()
    local star_color = skygen.default_star_params.star_color
    local heat,humidity = skygen.get_heat_humidity(biome_name)
    local sun_tint = skygen.biomes[biome_name].colors.sun_tint
    local cloud_color = {r = 255, g =  255, b =  255, a = 2.55 * humidity}
    local sun_texture = "sun.png"
    local moon_texture = "moon.png"
    local sun_scale = 1.0
    local moon_scale = 1.0

    if skygen.storage:get_string("event") ~= "none" then
        sun_tint = skygen.biomes[biome_name].event_colors.sun_tint
        cloud_color = skygen.event_data[skygen.storage:get_string("event")].color_cloud
        cloud_color.a = 2.55 * humidity
        sun_texture = skygen.event_data[skygen.storage:get_string("event")].sun_texture
        moon_texture = skygen.event_data[skygen.storage:get_string("event")].moon_texture
    end
    if skygen.read(name, "star_coloring") == "true" then
        star_color = sun_tint
    end
    if (skygen.read(name, "scaling")) == "true" then
        sun_scale = ((heat/100) + 0.1)*2
        moon_scale = ((heat/100) + 0.1)*4
    end

    player:set_clouds({
        density = humidity/150,
        color = cloud_color,
        thickness = humidity * 0.8
    })
    player:set_sun({
        texture = sun_texture,
        scale = sun_scale,
    })
    player:set_moon({
        texture = moon_texture,
        scale = moon_scale,
    })
    player:set_stars({
        count = (150 - humidity) * 0.4,
        star_color = star_color
    })
end

function skygen.set_sky_colors(player, biome_name)
    local base_values = skygen.biomes[biome_name].colors
    if skygen.storage:get_string("event") ~= "none" then
        base_values = skygen.biomes[biome_name].event_colors
    end

    local fog_distance = -1
    local fog_start = -1
    if (skygen.biomes[biome_name].fog_distance) then
        fog_distance = skygen.biomes[biome_name].fog_distance
    end
    if (skygen.biomes[biome_name].fog_start) then
        fog_start = skygen.biomes[biome_name].fog_start
    end

    player:set_sky({
        type = "regular",
        sky_color = {
            day_sky         = base_values.day,
            day_horizon     = base_values.day_horizon,
            dawn_sky        = base_values.dawn,
            dawn_horizon    = base_values.dawn_horizon,
            night_sky       = base_values.night,
            night_horizon   = base_values.night_horizon,
            indoors         = base_values.indoors,
            fog_sun_tint    = base_values.sun_tint,
            fog_moon_tint   = base_values.moon_tint,
            fog_tint_type   = "custom"
        }
    })

    local fog = skygen.biomes[biome_name].colors.fog
    if fog then
        local fog_color = skygen.biomes[biome_name].colors.fog
        if skygen.storage:get_string("event") ~= "none" then
            fog_color = skygen.biomes[biome_name].event_colors.fog
        end
        player:set_sky({
            fog = {
                fog_distance = fog_distance,
                fog_start = fog_start,
                fog_color = fog_color,
            }
        })
    else
        player:set_sky({
            fog = {
                fog_distance = -1,
                fog_start = -1,
                fog_color = "#00000000",
            }
        })
    end
end

function skygen.init_transition(player, prev_biome_name, biome_name)
    local name = player:get_player_name()
    skygen.write(name, "sky_state", "transition")

    local base_data = {}
    local diff_data = {}
    local fog_base = skygen.biomes[prev_biome_name].colors.fog
    local fog = skygen.biomes[biome_name].colors.fog
    local timeofday = "night"
    if (minetest.get_timeofday() > 0.25) and (minetest.get_timeofday() < 0.75) then
        timeofday = "day"
    end
    -- Fog interpolation: see [Fog Interpolation]
    if skygen.storage:get_string("event") == "none" then
        base_data.sun_tint = skygen.biomes[prev_biome_name].colors.sun_tint
        base_data.moon_tint = skygen.biomes[prev_biome_name].colors.moon_tint
        if fog_base then
            base_data.fog = skygen.biomes[prev_biome_name].colors.fog
        elseif fog then
            if timeofday == "day" then
                base_data.fog = skygen.biomes[prev_biome_name].colors.day_horizon
            else
                base_data.fog = skygen.colorize(skygen.biomes[prev_biome_name].colors.night_horizon, {r=0,g=0,b=0}, skygen.night_darken_amount)
            end
        end
    else
        base_data.sun_tint = skygen.biomes[prev_biome_name].event_colors.sun_tint
        base_data.moon_tint = skygen.biomes[prev_biome_name].event_colors.moon_tint
        if fog_base then
            base_data.fog = skygen.biomes[prev_biome_name].event_colors.fog
        elseif fog then
            if timeofday == "day" then
                base_data.fog = skygen.biomes[prev_biome_name].event_colors.day_horizon
            else
                base_data.fog = skygen.colorize(skygen.biomes[prev_biome_name].event_colors.night_horizon, {r=0,g=0,b=0}, skygen.night_darken_amount)
            end
        end
    end

    base_data.heat, base_data.humidity = skygen.get_heat_humidity(prev_biome_name)
    diff_data.sun_tint, diff_data.moon_tint, diff_data.fog = skygen.get_color_diffs(prev_biome_name, biome_name)
    diff_data.heat, diff_data.humidity = skygen.get_param_diffs(prev_biome_name, biome_name)

    local transition_start = 0
    skygen.set_biome_sky(player, prev_biome_name)
    skygen.loop_transition(player, base_data, diff_data, biome_name, transition_start)
end

function skygen.loop_transition(player, base_data, diff_data, biome, step)
    if step > skygen.biome_transition_frames then
        skygen.write(player:get_player_name(), "sky_state", "biome")
        skygen.set_biome_sky(player, biome)
        skygen.active_biome[player:get_player_name()] = biome
    else
        step = step + 1
        minetest.after(1 / skygen.biome_transition_frames, function()
            skygen.apply_transition_step(player, step, base_data, diff_data)
            skygen.loop_transition(player, base_data, diff_data, biome, step)
        end)
    end
end

function skygen.apply_transition_step(player, step, base_data, diff_data)
    local heat = base_data.heat + (diff_data.heat * step)
    local humidity = base_data.humidity + (diff_data.humidity * step)
    local scaled_sun_tint_diff = skygen.scale_colorspec(diff_data.sun_tint, step)
    local sun_tint = skygen.add_colorspec(base_data.sun_tint, scaled_sun_tint_diff)

    if diff_data.fog then
        local fog = skygen.add_colorspec(base_data.fog, skygen.scale_colorspec(diff_data.fog, step))
        player:set_sky({
            fog = {
                fog_color = fog,
            }
        })
    end

    local name = player:get_player_name()
    local cloud_color = {r = 255, g =  255, b =  255, a = 2.55 * humidity}
    local sun_texture = "sun.png"
    local moon_texture = "moon.png"
    local sun_scale = 1.0
    local moon_scale = 1.0

    if skygen.storage:get_string("event") ~= "none" then
        cloud_color = skygen.event_data[skygen.storage:get_string("event")].color_cloud
        cloud_color.a = 2.55 * humidity
        sun_texture = skygen.event_data[skygen.storage:get_string("event")].sun_texture
        moon_texture = skygen.event_data[skygen.storage:get_string("event")].moon_texture
    end
    if (skygen.read(name, "scaling")) == "true" then
        sun_scale = ((heat/100) + 0.1)*2
        moon_scale = ((heat/100) + 0.1)*4
    end
    local star_color = skygen.default_star_params.star_color
    if skygen.read(name, "star_coloring") == "true" then
        star_color = sun_tint
    end
    player:set_clouds({
        density = humidity/150,
        color = cloud_color,
        thickness = humidity * 0.8
    })
    player:set_sun({
        texture = sun_texture,
        scale = sun_scale,
    })
    player:set_moon({
        texture = moon_texture,
        scale = moon_scale,
    })
    player:set_stars({
        count = (150 - humidity) * 0.4,
        star_color = star_color
    })
end

function skygen.get_param_diffs(prev_biome_name, biome_name)
    local prev_heat,prev_humidity = skygen.get_heat_humidity(prev_biome_name)
    local heat,humidity = skygen.get_heat_humidity(biome_name)
    local results = {}
    results.heat = (heat - prev_heat) / skygen.biome_transition_frames
    results.humidity = (humidity - prev_humidity) / skygen.biome_transition_frames
    return results.heat, results.humidity
end

function skygen.get_color_diffs(prev_biome_name, biome_name)
    local prev_colorset = {}
    local colorset = {}
    local result = {}
    local fog_prev = skygen.biomes[prev_biome_name].colors.fog
    local fog = skygen.biomes[biome_name].colors.fog
    local timeofday = "night"
    if (minetest.get_timeofday() > 0.25) and (minetest.get_timeofday() < 0.75) then
        timeofday = "day"
    end
    if skygen.debug then
        print("Calculating transition from " .. prev_biome_name .. " to " .. biome_name .. "\n")
        if fog then
            print("Fog value is " .. dump(fog))
        end
        if fog_prev then
            print("Previous fog value is " .. dump(fog_prev))
        end
    end
    -- [Fog Interpolation]
    -- If the previous biome has fog and the next biome has fog then simply interpolate
    -- If one of the biomes doesn't have fog, but the other does, then the interpolation is more complex:
    -- Minetest considers fog color of #000000 as ignore, not black, so interpolating with it would cause glitches
    -- Instead of using the default value of #000000, the horizon color for day or night is appropriately chosen
    -- This approach lowers the occurrence of glitches but doesn't completely alleviate them
    if skygen.storage:get_string("event") == "none" then
        prev_colorset.sun_tint = skygen.biomes[prev_biome_name].colors.sun_tint
        prev_colorset.moon_tint = skygen.biomes[prev_biome_name].colors.moon_tint
        colorset.sun_tint = skygen.biomes[biome_name].colors.sun_tint
        colorset.moon_tint = skygen.biomes[biome_name].colors.moon_tint
        if fog_prev then
            prev_colorset.fog = skygen.biomes[prev_biome_name].colors.fog
        else
            if timeofday == "day" then
                prev_colorset.fog = skygen.biomes[prev_biome_name].colors.day_horizon
            else
                prev_colorset.fog = skygen.colorize(skygen.biomes[prev_biome_name].colors.night_horizon, {r=0,g=0,b=0}, skygen.night_darken_amount)
            end
        end
        if fog then
            colorset.fog = skygen.biomes[biome_name].colors.fog
        else
            if timeofday == "day" then
                colorset.fog = skygen.biomes[biome_name].colors.day_horizon
            else
                colorset.fog = skygen.colorize(skygen.biomes[biome_name].colors.night_horizon, {r=0,g=0,b=0}, skygen.night_darken_amount)
            end
        end
    else
        prev_colorset.sun_tint = skygen.biomes[prev_biome_name].event_colors.sun_tint
        prev_colorset.moon_tint = skygen.biomes[prev_biome_name].event_colors.moon_tint
        colorset.sun_tint = skygen.biomes[biome_name].event_colors.sun_tint
        colorset.moon_tint = skygen.biomes[biome_name].event_colors.moon_tint
        if fog_prev then
            prev_colorset.fog = skygen.biomes[prev_biome_name].event_colors.fog
        else
            if timeofday == "day" then
                prev_colorset.fog = skygen.biomes[prev_biome_name].event_colors.day_horizon
            else
                prev_colorset.fog = skygen.colorize(skygen.biomes[prev_biome_name].event_colors.night_horizon, {r=0,g=0,b=0}, skygen.night_darken_amount)
            end
        end
        if fog then
            colorset.fog = skygen.biomes[biome_name].event_colors.fog
        else
            if timeofday == "day" then
                colorset.fog = skygen.biomes[biome_name].event_colors.day_horizon
            else
                colorset.fog = skygen.colorize(skygen.biomes[biome_name].event_colors.night_horizon, {r=0,g=0,b=0}, skygen.night_darken_amount)
            end
        end
    end
    result.sun_tint = {
        r = (colorset.sun_tint.r - prev_colorset.sun_tint.r) / skygen.biome_transition_frames,
        g = (colorset.sun_tint.g - prev_colorset.sun_tint.g) / skygen.biome_transition_frames,
        b = (colorset.sun_tint.b - prev_colorset.sun_tint.b) / skygen.biome_transition_frames
    }
    result.moon_tint = {
        r = (colorset.moon_tint.r - prev_colorset.moon_tint.r) / skygen.biome_transition_frames,
        g = (colorset.moon_tint.g - prev_colorset.moon_tint.g) / skygen.biome_transition_frames,
        b = (colorset.moon_tint.b - prev_colorset.moon_tint.b) / skygen.biome_transition_frames
    }
    result.fog = false
    if fog_prev or fog then
        result.fog = {
            r = (colorset.fog.r - prev_colorset.fog.r) / skygen.biome_transition_frames,
            g = (colorset.fog.g - prev_colorset.fog.g) / skygen.biome_transition_frames,
            b = (colorset.fog.b - prev_colorset.fog.b) / skygen.biome_transition_frames
        }
    end
    return result.sun_tint, result.moon_tint, result.fog
end