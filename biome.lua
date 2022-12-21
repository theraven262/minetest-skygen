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
end

function skygen.init_transition(player, prev_biome_name, biome_name)
    local name = player:get_player_name()
    skygen.write(name, "sky_state", "transition")

    local base_data = {}
    local diff_data = {}

    if skygen.storage:get_string("event") == "none" then
        base_data.sun_tint = skygen.biomes[prev_biome_name].colors.sun_tint
        base_data.moon_tint = skygen.biomes[prev_biome_name].colors.moon_tint
    else
        base_data.sun_tint = skygen.biomes[prev_biome_name].event_colors.sun_tint
        base_data.moon_tint = skygen.biomes[prev_biome_name].event_colors.moon_tint
    end

    base_data.heat, base_data.humidity = skygen.get_heat_humidity(prev_biome_name)
    diff_data.sun_tint, diff_data.moon_tint = skygen.get_color_diffs(prev_biome_name, biome_name)
    diff_data.heat, diff_data.humidity = skygen.get_param_diffs(prev_biome_name, biome_name)

    local transition_start = 0
    skygen.loop_transition(player, base_data, diff_data, biome_name, transition_start)
end

function skygen.loop_transition(player, base_data, diff_data, biome, step)
    if step > skygen.biome_transition_frames then
        skygen.write(player:get_player_name(), "sky_state", "biome")
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
    if skygen.storage:get_string("event") == "none" then
        prev_colorset.sun_tint = skygen.biomes[prev_biome_name].colors.sun_tint
        prev_colorset.moon_tint = skygen.biomes[prev_biome_name].colors.moon_tint
        colorset.sun_tint = skygen.biomes[biome_name].colors.sun_tint
        colorset.moon_tint = skygen.biomes[biome_name].colors.moon_tint
    else
        prev_colorset.sun_tint = skygen.biomes[prev_biome_name].event_colors.sun_tint
        prev_colorset.moon_tint = skygen.biomes[prev_biome_name].event_colors.moon_tint
        colorset.sun_tint = skygen.biomes[biome_name].event_colors.sun_tint
        colorset.moon_tint = skygen.biomes[biome_name].event_colors.moon_tint
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
    return result.sun_tint, result.moon_tint
end