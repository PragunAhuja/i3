#!/bin/bash

if [ ! $XDG_DATA_HOME ]; then
	export XDG_DATA_HOME="/home/$(whoami)/.local/share"
	echo -e "\nexport XDG_DATA_HOME=\"/home/$(whoami)/.local/share\"" >>  ~/.bashrc
fi

cd $XDG_DATA_HOME
mkdir -p flatpak/extension/app.zen_browser.zen.systemconfig/x86_64/stable

cd flatpak/extension/app.zen_browser.zen.systemconfig/x86_64/stable

wget https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/master/program/config.js > /dev/null 2>&1
mkdir -p defaults/pref
cd defaults/pref
wget https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/master/program/defaults/pref/config-prefs.js > /dev/null 2>&1

cd ~/.var/app/app.zen_browser.zen/.zen/

# List all directories and save them to an array
mapfile -t dirs < <(find . -maxdepth 1 -type d ! -name 'Profile Groups' ! -name '.' -printf '%f\n')

# Check if the array is empty
if [ ${#dirs[@]} -eq 0 ]; then
    echo "No profiles found."
    exit 1
fi

# Display the directories with a number
echo "Select a profile:"
for i in "${!dirs[@]}"; do
    echo "$((i + 1)): ${dirs[$i]}"
done

# Read user input
read -p "Enter the number of the profile you want to install Sine into: " choice

# Validate input
if [[ ! $choice =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#dirs[@]}" ]; then
    echo "Invalid selection."
    exit 1
fi

# Change into the selected directory
cd "${dirs[$((choice - 1))]}"


mkdir -p chrome
cd chrome

mkdir -p  JS
mkdir -p  utils

cd utils
wget https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/master/profile/chrome/utils/boot.sys.mjs > /dev/null 2>&1
wget https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/master/profile/chrome/utils/chrome.manifest > /dev/null 2>&1
wget https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/master/profile/chrome/utils/fs.sys.mjs > /dev/null 2>&1
wget https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/master/profile/chrome/utils/module_loader.mjs > /dev/null 2>&1
wget https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/master/profile/chrome/utils/uc_api.sys.mjs > /dev/null 2>&1
wget https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/master/profile/chrome/utils/utils.sys.mjs > /dev/null 2>&1

cd ../

cd JS
wget https://raw.githubusercontent.com/CosmoCreeper/Sine/main/deployment/engine.zip > /dev/null 2>&1
unzip engine.zip > /dev/null 2>&1
rm engine.zip

echo -e "\nWe have successfully installed Sine on your system!"
echo -e "\nRemaining steps:"
echo "1. Open Zen Browser (flatpak)"
echo "2. Navigate to about:support"
echo "3. Clear startup cache and restart your browser"
echo "4. Visit the settings page to begin your journey with Sine"

echo -e "\nWe wish the best for you, and thank you for testing out Sine on flatpak!"
