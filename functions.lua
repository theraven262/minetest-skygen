function skygen.read(name, var)
    return skygen.storage:get_string(name .. "_" .. var)
end

function skygen.write(name, var, value)
    skygen.storage:set_string(name .. "_" .. var, value)
end

function skygen.verify_event(event)
    return skygen.event_data[event] ~= nil
end

function skygen.verify_skybox(skybox)
    return skygen.skyboxes[skybox] ~= nil
end

function skygen.verify_biome(biome_name)
	if skygen.biomes[biome_name] then
		return biome_name
	else
		return skygen.fallback_biome
	end
end

function skygen.fetch_biome (player)
    local player_pos = player:get_pos()
    local biome_data = minetest.get_biome_data(player_pos)
    local biome = minetest.get_biome_name(biome_data.biome)
    biome = skygen.verify_biome(biome)
    return biome
end

function skygen.get_heat_humidity(biome_name)
    local heat = 50
    local humidity = 50
    if minetest.registered_biomes[biome_name] ~= nil then
        heat = minetest.registered_biomes[biome_name].heat_point
        humidity = minetest.registered_biomes[biome_name].humidity_point
    end
    return heat,humidity
end

function skygen.colorize(color, colorizer, amount)
    local difference = {
        r = colorizer.r - color.r,
        g = colorizer.g - color.g,
        b = colorizer.b - color.b
    }
    local result = {
        r = color.r + (difference.r * amount),
        g = color.g + (difference.g * amount),
        b = color.b + (difference.b * amount)
    }
    return result
end

function skygen.scale_colorspec(color, amount)
    return {
        r = color.r * amount,
        g = color.g * amount,
        b = color.b * amount
    }
end

function skygen.add_colorspec(color1, color2)
    return {
        r = color1.r + color2.r,
        g = color1.g + color2.g,
        b = color1.b + color2.b,
    }
end