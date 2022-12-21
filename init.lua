skygen = {}
skygen.sky_state = {}
skygen.active_biome = {}
skygen.skyboxes = {}
skygen.skybox_names = {}
skygen.event_data = {}
skygen.storage = minetest.get_mod_storage()
skygen.tables_built = false

local mods = minetest.get_modnames()
skygen.is_edgy = false
local weather_presence = false
for i=1,#mods do
    if mods[i] == "ccore" then
        skygen.is_edgy = true
    end
    if mods[i] == "weather" then
        weather_presence = true
    end
end

if skygen.is_edgy then
    skygen.edgy_skyboxes = {"test_sky", "sky"}
    table.insert_all(skygen.skybox_names, skygen.edgy_skyboxes)
end

if weather_presence then
    minetest.settings:set_bool("enable_weather", false)
end

-- Event can not be stored in a variable, it has to be evaluated every time
if skygen.storage:get_string("event") == "" then
    skygen.storage:set_string("event", "none")
end

local path = minetest.get_modpath("skygen")
local skybox_path = path .. "/textures/skyboxes"
dofile(path.."/vars.lua")
dofile(path.."/colors.lua")
dofile(path.."/biome.lua")
dofile(path.."/skybox.lua")
dofile(path.."/events.lua")
dofile(path.."/functions.lua")
dofile(path.."/globalstep.lua")
dofile(path.."/strings.lua")
dofile(path.."/chatcommands.lua")

for i=1,#skygen.skybox_names do
    if not skygen.skybox_names[i] then
        return
    else
        dofile(skybox_path .. "/" .. skygen.skybox_names[i] .. "/skydef.lua")
        print("Skygen: Loaded skybox \"" .. skygen.skybox_names[i] .. "\".")
    end
end

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    -- In case of a server crash
    if skygen.read(name, "sky_state") == "transition" then
        skygen.write(name, "sky_state", "biome")
    end
    if skygen.read(name, "sky_state") == "skybox" then
        skygen.set_skybox(player, skygen.read(name, "skybox"))
    end
    skygen.set_base_vars(name)
    skygen.set_customization_vars(name)
    skygen.set_shadows(player)
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    if skygen.read(name, "sky_state") == "transition" then
        skygen.write(name, "sky_state", "biome")
    end
end)

function skygen.set_base_vars(name)
    if skygen.is_edgy then -- Server's spawn is in the sky skybox
        if skygen.read(name, "sky_state") == "" then
            local player = minetest.get_player_by_name(name)
            skygen.set_skybox(player, "sky")
        end
    else
        if skygen.read(name, "sky_state") == "" then
            skygen.write(name, "sky_state", skygen.default_state)
        end
        if skygen.read(name, "skybox") == "" then
            skygen.write(name, "skybox", skygen.default_skybox)
        end
    end
    if skygen.read(name, "backup_state") == "" then
        skygen.write(name, "backup_state", "biome")
    end
    if skygen.read(name, "backup_skybox") == "" then
        skygen.write(name, "backup_skybox", "none")
    end
end

function skygen.set_customization_vars(name)
    if skygen.read(name, "star_coloring") == "" then
        skygen.write(name, "star_coloring", skygen.default_star_coloring)
    end
    if skygen.read(name, "scaling") == "" then
        skygen.write(name, "scaling", skygen.default_scaling)
    end
    if skygen.read(name, "shadow_intensity") == "" then
        skygen.write(name, "shadow_intensity", skygen.default_shadow_intensity)
    end
end

function skygen.set_shadows(player)
    local name = player:get_player_name()
    player:set_lighting({ shadows = { intensity = skygen.read(name, "shadow_intensity") } })
end

function skygen.build_color_tables()
    for biome_name in pairs(skygen.biomes) do
        skygen.build_biome_colors(biome_name)
    end
    local event_name = skygen.storage:get_string("event")
    local event_on = event_name ~= "none"
    local event_exists = skygen.verify_event(event_name)
    if event_exists and event_on then
        for biome_name in pairs(skygen.biomes) do
            skygen.build_event_colors(biome_name)
        end
    end
end

function skygen.build_biome_colors(biome_name)
    local biome_data = skygen.biomes[biome_name]
    local biome_colors = biome_data.colors
    if not (biome_colors.indoors) then
        biome_colors.indoors = {r=128,g=128,b=128}
    end

    biome_colors.dawn           = skygen.colorize(biome_colors.day_horizon, biome_colors.sun_tint, skygen.dawn_colorizer_intensity)
    biome_colors.dawn_horizon   = skygen.colorize(biome_colors.day,         biome_colors.sun_tint, skygen.dawn_colorizer_intensity)
    biome_colors.night          = skygen.colorize(biome_colors.day,         biome_colors.moon_tint, skygen.night_colorizer_intensity)
    biome_colors.night_horizon  = skygen.colorize(biome_colors.day_horizon, biome_colors.moon_tint, skygen.night_colorizer_intensity)
end

function skygen.build_event_colors(biome_name)
    local biome_data = skygen.biomes[biome_name]
    local biome_colors = biome_data.colors
    local event = skygen.storage:get_string("event")
    local event_main_col = skygen.event_data[event].color
    local event_sun_col = skygen.event_data[event].color_sun
    local event_moon_col = skygen.event_data[event].color_moon
    local event_night_col = skygen.event_data[event].color_night
    local event_biome_colors = {}
    local amount = skygen.event_colorizer_intensity
    event_biome_colors.day              = skygen.colorize(biome_colors.day,             event_main_col, amount)
    event_biome_colors.day_horizon      = skygen.colorize(biome_colors.day_horizon,     event_main_col, amount)
    event_biome_colors.sun_tint         = skygen.colorize(biome_colors.sun_tint,        event_sun_col, amount)
    event_biome_colors.moon_tint        = skygen.colorize(biome_colors.moon_tint,       event_moon_col, amount)
    event_biome_colors.indoors          = skygen.colorize(biome_colors.indoors,         event_main_col, amount)
    event_biome_colors.dawn             = skygen.colorize(biome_colors.dawn,            event_sun_col, amount)
    event_biome_colors.dawn_horizon     = skygen.colorize(biome_colors.dawn_horizon,    event_sun_col, amount)
    event_biome_colors.night            = skygen.colorize(biome_colors.night,           event_night_col, amount)
    event_biome_colors.night_horizon    = skygen.colorize(biome_colors.night_horizon,   event_night_col, amount)
    biome_data.event_colors = event_biome_colors
end