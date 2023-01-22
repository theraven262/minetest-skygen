minetest.register_chatcommand("skygen", {
    params = "<option> <parameter>",
    description = skygen.chatcommand_settings,
    func = function(name, param)
        local parameters = {}
        local param_position = 1
        -- Matches words separated by space
        for i in param:gmatch("%g+") do
            parameters[param_position] = i
            param_position = param_position + 1
        end
        if parameters[1] == "off" then
            skygen.deactivate(name)
            minetest.chat_send_player(name, skygen.chatcommand_deactivate)
        elseif parameters[1] == "biome" then
            skygen.biome_mode(name)
            minetest.chat_send_player(name, skygen.chatcommand_biome)
        elseif parameters[1] == "skybox" then
            skygen.choose_skybox(name, parameters[2])
        elseif parameters[1] == "shadow" then
            skygen.choose_shadow(name, parameters[2])
        elseif parameters[1] == "toggle_star_color" then
            skygen.toggle(name, "star_color")
        elseif parameters[1] == "toggle_scaling" then
            skygen.toggle(name, "scaling")
        end
    end
})

function skygen.choose_shadow(name, intensity)
    local player = minetest.get_player_by_name(name)
    skygen.write(name, "shadow_intensity", intensity)
    minetest.chat_send_player(name, skygen.chatcommand_shadow .. intensity .. ".")
    skygen.set_shadows(player)
end

function skygen.choose_skybox(name, skybox)
    if skygen.verify_skybox(skybox) then
        local sky_description = skygen.skyboxes[skybox].description
        skygen.set_skybox(minetest.get_player_by_name(name), skybox)
        minetest.chat_send_player(name, skygen.chatcommand_set_skybox .. sky_description)
    else
        minetest.chat_send_player(name, skygen.chatcommand_invalid_skybox)
    end
end

function skygen.toggle(name, setting)
    if skygen.read(name, setting) == "true" then
        skygen.write(name, setting, "false")
        minetest.chat_send_player(name, skygen.toggle_strings[setting].off)
    else
        skygen.write(name, setting, "true")
        minetest.chat_send_player(name, skygen.toggle_strings[setting].on)
    end
end

function skygen.deactivate(name)
    local player = minetest.get_player_by_name(name)
    skygen.write(name, "sky_state", "inactive")
    player:set_sky()
    player:set_sun()
    player:set_stars(skygen.default_star_params)
    player:set_moon()
    player:set_clouds()
    player:override_day_night_ratio(nil)
end

function skygen.biome_mode(name)
    skygen.write(name, "skybox", "none")
    skygen.write(name, "sky_state", "biome")
    skygen.active_biome[name] = nil
    local player = minetest.get_player_by_name(name)
    player:set_sky()
    player:override_day_night_ratio(nil)
    player:set_sun()
    player:set_moon()
    player:set_stars(skygen.default_star_params)
end

minetest.register_chatcommand("skygen_event", {
    params = "<event_name>",
    description = "Initiate an event",
    privs = {server=true},
    func = function(name, param)
        if (param == "deactivate") and (skygen.storage:get_string("event") ~= "none") then
            skygen.end_event()
        else
            if skygen.storage:get_string("event") ~= "none" then
                skygen.end_event()
            end
            skygen.start_event(param)
        end
    end
})

function skygen.end_event()
    minetest.chat_send_all(skygen.event_data[skygen.storage:get_string("event")].end_message)
    skygen.storage:set_string("event", "none")
    skygen.tables_built = false
end

function skygen.start_event(event)
    if skygen.verify_event(event) then
        skygen.storage:set_string("event", event)
        skygen.tables_built = false
        minetest.chat_send_all(skygen.event_data[event].start_message)
    end
end
