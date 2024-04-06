# What it is
This plugin adds a dock to the bottom of the screen. Similar to what you would see in Unity or Unreal. It allows you to preview assets and drag them into the scene.

# Settings
Settings can be found in addons/asset_dock/settings.tres you can configure the following settings

root_folder_path - This is the root file path of Asset Dock it will load all files in this directory and any files in folders

file_types - An array of file types that will be displayed in the dock if empty all file types will be shown by default this is set to only show png and tscn files

hide_empty_folders - If true empty folders will not be shown in the dock

If you want to adjust the resolution of thumbnails in the dock do the following.
Go to Editor->FileSystem->File Dialog there you can adjust the size of preview thumbnails by default it's set to 64

# Setup
By default the root folder is set to res://. I recommend creatting a folder called Assets and setting that as the root folder. This way only assets on that folder will be loaded instead of all assets in your project which helps on performance.
There is also an issue with godot where previews for tscn files will not generate if the root folder is set res:// this is an issue am currently looking to. 

# Planned features
Right the dock just mimics what is shown in the file system you can't change files from the dock so here is list of planned features
- Create folders in the dock
- Delete files, rename files, move files inside of the dock
- Drag files on to the dock to import them into the project like yoou would with the file system

# How It Looks
![image](https://github.com/Reetro/Asset-Dock/assets/29167997/f8a22149-5417-4616-82b2-445a245c40fe)
