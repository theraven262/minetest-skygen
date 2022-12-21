# SkyGen

Is a minetest mod that changes the sky based on the player's current biome (plus some other sky-related stuff).

## Features
- Sky colorization
- Sun and moon scaling according to the biome's _heat_
- Setting the star amount according to biome's _humidity_
- Star colorization
- Cloud resizing according to biome's _humidity_
- Smooth transitions when changing the above
- Per-player skybox handling
- Activates minetest's dynamic shadows and allows tweaking intensity
- Supports defining server-wide events, which colorize the sky and can set custom sun and moon graphics

## Usage
The `/skygen <param1> <param2>` chatcommand allows access to the options for each player.
These are:
1. `off` - Deactivates SkyGen 
2. `biome` - Switches to the biome mode
3. `skybox <skybox_name>` - Sets the player's skybox
4. `shadow <intensity>` - Tweaks minetest's dynamic shadow intensity
5. `toggle_star_color` - Toggles star colorization
6. `toggle_scaling` - Toggles the sun and moon scaling

Server admins can initiate events using the `/skygen_event` chatcommand.
The event command has two options:
1. `<event_name>` - Starts an event if it exists
2. `deactivate` - Ends an active event

## Modding
Skygen is expandable with custom skyboxes, events and new biome colors.

### Adding custom biome colors
A color definition is appended to the `skygen.colors` table and looks like the following:
>      grassland = {
>        name = "Grassland",
>        colors = {
>            day         = {r=160,g=199,b=246},
>            day_horizon = {r=39,g=115,b=185},
>            sun_tint    = {r=222,g=99,b=0},
>            moon_tint   = {r=18,g=103,b=182},
>            indoors     = {r=128,g=128,b=128},
>        }
>     } 

The key has to be the same as the biome name that the color definition corresponds to.

If your biome is unknown to skygen, it will color its sky with the definition specified in the `skygen.fallback_biome` variable.

### Adding custom skyboxes
The skybox name has to be added to the `skygen.skybox_names` table in order for your skybox to be visible to SkyGen.
The skybox definition is placed into the `skygen_path/textures/skyboxes/<skybox_name>/skydef.lua`. It should have the following contents:
>       skygen.skyboxes.test_sky = {
>           description = "Test",
>           color = '#402639',
>           clouds = true,
>           time = 5000,
>           change_sun = true,
>           sunrise_visible = false,
>           sun_scale = 8,
>           change_moon = "none",
>           --moon_scale
>           change_stars = "none",
>           --star_count
>           --star_color
>           --star_scale
>           change_clouds = "none",
>           --cloud_density
>           --cloud_color
>           --cloud_ambient
>           --cloud_height
>           --cloud_thickness
>           --cloud_speed
>       }

The `color` field sets the color of the fog.

The `time` field sets the skybox' time of day, it can be removed for the default day/night cycle.

The fields that accept `true/false/"none"` options are `clouds, change_sun, change_moon, change_stars, change_clouds`. These work like so:

- `true` makes SkyGen read the related fields and apply them
- `false` makes SkyGen ignore the related fields and use default Minetest values
- `"none"` removes the object from the sky

The rest of the fields are handled over to minetest and their documentation is found over at [the lua api documentation](https://github.com/minetest/minetest/blob/master/doc/lua_api.txt).

### Making events
An event definition is appended to the `skygen.event_data` table.
The definition looks like this:
>       skygen.event_data.test = {
>           description = "Test",
>           start_message = "The Test has Arrived!",
>           end_message = "The Test has Ended!",
>           moon = "moonfall_moon.png",
>           sun = "sun.png",
>           color = {r=0, g=255, b=0},
>           color_night = {r=0, g=255, b=0},
>           color_cloud = {r=255, g=0, b=0},
>           color_sun = {r=0, g=255, b=0},
>           color_moon = {r=0, g=255, b=0},
>       }

The color definitions are used to tint the biome colors. The amount of tint is described globally by the `skygen.event_colorizer_intensity` variable.

## Global settings
The `strings.lua` contains variables that store strings which trigger on chatcommands. This can be useful if you're making a game that needs skygen to be more integrated into your game world.

The global customizable variables are stored in the `vars.lua`. There is only a couple that need explanation/warning:

- `skygen.biome_transition_frames` - should not go much higher than 16, as it is used to calculate the amount of change to scaled objects per transition step and higher numbers then introduce more approximations into the calculation.
- `skygen.default_state` - if you change this to `skybox` you also need to provide the `skygen.default_skybox` or the game will crash when the new player joins (since no skyboxes are included by default).
- `skygen.sky_biome_start` - is a little override for the custom game that skygen is made for, but you can easily adapt it for your own use by flipping a few switches. You'll need the skybox for it which is in [a separate repository](https://github.com/theraven262/minetest-skygen-skyboxes).
