# What it is
This plugin adds a dock to the bottom of the screen. Similar to what you would see in Unity or Unreal. It allows you to preview assets and drag them into the scene.

# What it looks like
![image](https://github.com/Reetro/Asset-Dock/assets/29167997/762fb082-9dd0-4427-8848-672693bf7ef8)

# Settings
Settings can be found in addons/asset_dock/settings.tres you can configure the following settings

root_folder_path - This is the root file path of Asset Dock it will load all files in this directory and any files in folders

file_types - An array of file types that will be displayed in the dock if empty all file types will be shown by default this is set to only show png and tscn files

show_empty_folders - If true empty folders will be shown in the dock by default this is false

If you want to adjust the resolution of thumbnails in the dock do the following.
Go to Editor->FileSystem->File Dialog there you can adjust the size of preview thumbnails by default it's set to 64

# Setup
By default the root folder is set to res://. I recommend creating a folder called Assets and setting that as the root folder. This way only assets on that folder will be loaded instead of all assets in your project which helps on performance. 

# Collections
Collections are a way to group a bunch of assets together. To create a collection click on the collections tab. Then click on the add collection button and the collection a name.

![create collection](https://github.com/Reetro/Asset-Dock/assets/29167997/8335eedf-47c3-486c-9fcc-750b7759b378)

To add items to a collection click on the collection and drag and drop the files on to the dock. If you drop a folder on to the dock will get all the files from that folder and add them.

![add items](https://github.com/Reetro/Asset-Dock/assets/29167997/c58a7672-f739-45dd-9afd-a96c34fd283e)

To remove items from a collection right click and click remove.

![remove item](https://github.com/Reetro/Asset-Dock/assets/29167997/07540cb3-ca85-44ed-b77c-1bc7c1171265)

To delete a collection right click on a collection on the left panel and click delete.

![delete collection](https://github.com/Reetro/Asset-Dock/assets/29167997/52f7cc64-6eed-4b84-a597-456a21ac1b7d)
