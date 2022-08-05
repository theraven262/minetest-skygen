# minetest-skygen
Adaptive sky mod for Minetest.
Supports skyboxes, custom color schemes and custom server-wide events.
Three modes are available to the players: biome, skybox and inactive (default minetest sky); These are set by the player using the /skygen command
Events change the overall color in the biome mode, for everyone on the server. An event can also change the textures of sun and moon, as well as the cloud color.
Events can be started and ended using the /skygen_event command.
Events and player's sky choice persist over server restarts/reconnects.

Skyboxes are defined using a custom file, placed in skyboxes/ .
The file has to have the same name as the skybox string, which has to be added to the skygen.skybox_names table.
The skybox textures also have to have a name consisting of the skybox string with the number of the skybox side appended.
The numbering is exactly the same as the order of inputs for minetest's set_sky() textures. 
The example settings are provided in the test_sky example.

Events are registered as an entry in the skygen.event_data table. An event string has to be added to skygen.events as well.
Custom event settings are likewise demonstrated in the test event example.

Skygen biome mode can also be extended to support additional biomes, by adding appropriate biome entries into the skygen.biome_names and skygen.biomes tables in colors.lua .