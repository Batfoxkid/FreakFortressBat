mkdir build
cd build

wget --input-file=http://sourcemod.net/smdrop/$SM_VERSION/sourcemod-latest-linux
tar -xzf $(cat sourcemod-latest-linux)

cp -r ../addons/sourcemod/scripting addons/sourcemod
cd addons/sourcemod/scripting

wget "https://raw.githubusercontent.com/asherkin/TF2Items/master/pawn/tf2items.inc" -O include/tf2items.inc
wget "https://raw.githubusercontent.com/FlaminSarge/tf2attributes/master/tf2attributes.inc" -O include/tf2attributes.inc