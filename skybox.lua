skygen.set_skybox = function(player, skybox)
    local name = player:get_player_name()
    skygen.write(name, "skybox", skybox)
    skygen.write(name, "sky_state", "skybox")
    local skybox_data = skygen.skyboxes[skybox]
    local skybox_textures = {}
    for i=1,6 do
        skybox_textures[i] = "skygen_" .. skybox .. i .. ".png"
    end
    local fog_distance = -1
    local fog_start = -1
    local fog_color = {r=0,g=0,b=0}
    if skybox_data.fog_distance then
        fog_distance = skybox_data.fog_distance
    end
    if skybox_data.fog_start then
        fog_start = skybox_data.fog_start
    end
    if skybox_data.fog_color then
        fog_color = skybox_data.fog_color
    end
    player:set_sky({
        type = "skybox",
        base_color = skybox_data.color,
        textures = skybox_textures,
        clouds =  skybox_data.clouds,
        fog = {
            fog_distance = fog_distance,
            fog_start = fog_start,
            fog_color = fog_color
        }
    })
    if skybox_data.time ~= nil then
        player:override_day_night_ratio(skybox_data.time / 12000)
    end
    if skybox_data.change_sun == true then
        local sun_texture
        local sunrisebg_texture
        if (skybox_data.sun_texture == "default") or (skybox_data.sun_texture == nil) then
            sun_texture = "sun.png"
        else
            sun_texture = "skygen_" .. skybox .. "_sun.png"
        end
        if (skybox_data.sunrisebg_texture == "default") or (skybox_data.sunrisebg_texture == nil) then
            sunrisebg_texture = "sunrisebg.png"
        else
            sunrisebg_texture = "skygen_" .. skybox .. "_sunrisebg.png"
        end
        player:set_sun({
            texture = sun_texture,
            sunrise = sunrisebg_texture,
            sunrise_visible = skybox_data.sunrise_visible,
            scale = skybox_data.sun_scale,
        })
    elseif skybox_data.change_sun == "none" then
        player:set_sun({
            visible = false,
            sunrise_visible = false,
        })
    else
        player:set_sun()
    end
    if skybox_data.change_moon == true then
        local moon_texture
        if (skybox_data.moon_texture == "default") or (skybox_data.moon_texture == nil) then
            moon_texture = "moon.png"
        else
            moon_texture = "skygen_" .. skybox .. "_moon.png"
        end
        player:set_moon({
            texture = moon_texture,
            scale = skybox_data.moon_scale,
        })
    elseif skybox_data.change_moon == "none" then
        player:set_moon({
            visible = false,
        })
    else
        player:set_moon()
    end
    if skybox_data.change_stars == true then
        player:set_stars({
            count = skybox_data.star_count,
            color = skybox_data.star_color,
            scale = skybox_data.star_scale,
        })
    elseif skybox_data.change_stars == "none" then
        player:set_stars({
            visible = false,
        })
    else
        player:set_stars(skygen.default_star_parameters)
    end
    if skybox_data.change_clouds == true then
        player:set_clouds({
            density = skybox_data.cloud_density,
            color = skybox_data.cloud_color,
            ambient = skybox_data.cloud_ambient,
            height = skybox_data.cloud_height,
            thickness = skybox_data.cloud_thickness,
            speed = skybox_data.cloud_speed,
        })
    elseif skybox_data.change_clouds == "none" then
        player:set_clouds({
            density = 0,
        })
    else
        player:set_clouds()
    end
end
