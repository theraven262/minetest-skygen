minetest.register_globalstep(function()
    local players = minetest.get_connected_players()
    if skygen.tables_built == false then
        skygen.tables_built = true
        skygen.build_color_tables()
    end
    for i=1,#players do
        local player = players[i]
        skygen.update_sky(player)
    end
end)

function skygen.update_sky(player)
    local name = player:get_player_name()
    local sky_state = skygen.read(name, "sky_state")

    if skygen.is_edgy then
        skygen.handle_sky_override(player)
    end

    if sky_state == "biome" then
        skygen.update_biome_sky(player)
    end
end

function skygen.update_biome_sky(player)
    local name = player:get_player_name()
    local biome_name = skygen.fetch_biome(player)
    local previous_biome_name = skygen.active_biome[name]
    if previous_biome_name == biome_name then
        return
    elseif previous_biome_name == nil then
        skygen.active_biome[name] = biome_name
        skygen.set_biome_sky(player, biome_name)
    else
        skygen.set_sky_colors(player, biome_name)
        skygen.init_transition(player, previous_biome_name, biome_name)
    end
end

function skygen.handle_sky_override(player)
    local name = player:get_player_name()
    local sky_state = skygen.read(name, "sky_state")
    local active_skybox = skygen.read(name, "skybox")
    local player_height = player:get_pos().y
    local player_has_sky_skybox = (active_skybox == "sky") and (sky_state == "skybox")
    local player_in_sky_limits = player_height > skygen.sky_biome_start

    if player_in_sky_limits then
        if not player_has_sky_skybox then
            skygen.save_on_override(player)
            skygen.set_skybox(player, "sky")
        end
    else
        if player_has_sky_skybox then
            skygen.recover_from_override(player)
        end
    end
end

function skygen.save_on_override(player)
    local name = player:get_player_name()
    local sky_state = skygen.read(name, "sky_state")
    local saved_state
    if sky_state == "skybox" then
        local backup_skybox = skygen.read(name, "skybox")
        skygen.write(name, "backup_skybox", backup_skybox)
    elseif sky_state == "transition" then
        saved_state = "biome"
    else
        saved_state = sky_state
    end
    skygen.write(name, "backup_state", saved_state)
end

function skygen.recover_from_override(player)
    local name = player:get_player_name()
    local backup_state = skygen.read(name, "backup_state")
    local backup_skybox = skygen.read(name, "backup_skybox")
    skygen.write(name, "sky_state", backup_state)
    if backup_state == "skybox" then
        skygen.write(name, "skybox", backup_skybox)
    else
        skygen.write(name, "skybox", "none")
    end
    if skygen.read(name, "backup_state") == "biome"  then
        skygen.biome_mode(name)
    end
end