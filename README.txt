Repo is divided into two main sections.

raw_assets is for all of the files supporting the project that aren't going to be packaged with the project itself, e.g. Aseprite files, FMOD projects, DAW project files, etc.

 - Feel free to structure the 2d_art, music, and sfx folders for your part of the project according to your preferences/preferred workflow
 - The FMOD project files live in this folder, but banks will build directly to the relevant folder in godot_project

godot_project is for everything that will be part of the packaged game, including imported sprites, scene files, scripts, etc.

 - Assets aren't organized by file type, but by gameplay function (e.g. the player_character folder will contain all player sprites, as well as the player character scene and animations. Environment will contain scenery, tilemaps, etc). Depending on the game we decide to make, we may add additional folders for organization.
 - No audio files will need to go in this folder, as all sound will be organized in the fmod project folder and is automatically built into fmod_banks.
 - The autoload folder contains scripts that will store persistent game data (e.g. persistent music across scenes will be handled in the audio_manager)