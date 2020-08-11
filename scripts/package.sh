cd build

mkdir -p package/addons/sourcemod/plugins
mkdir -p package/addons/sourcemod/gamedata
mkdir -p package/addons/sourcemod/data
mkdir -p package/addons/sourcemod/configs

cp -r addons/sourcemod/plugins/freak_fortress_2.smx package/addons/sourcemod/plugins
cp -r ../addons/sourcemod/gamedata/equipwearable.txt package/addons/sourcemod/gamedata
cp -r ../addons/sourcemod/data/freak_fortress_2 package/addons/sourcemod/data
cp -r ../addons/sourcemod/configs/freak_fortress_2 package/addons/sourcemod/configs
cp -r ../addons/sourcemod/translations package/addons/sourcemod