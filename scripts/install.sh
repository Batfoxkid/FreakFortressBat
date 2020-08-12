mkdir build
cd build

wget --input-file=http://sourcemod.net/smdrop/$SM_VERSION/sourcemod-latest-linux
tar -xzf $(cat sourcemod-latest-linux)

cp -r ../addons/sourcemod/scripting addons/sourcemod
cd addons/sourcemod/scripting

wget "https://raw.githubusercontent.com/asherkin/TF2Items/master/pawn/tf2items.inc" -O include/tf2items.inc
wget "https://raw.githubusercontent.com/DoctorMcKay/sourcemod-plugins/master/scripting/include/morecolors.inc" -O include/morecolors.inc
wget "https://raw.githubusercontent.com/JoinedSenses/SteamTools/patch-1/plugin/steamtools.inc" -O include/steamtools.inc
wget "https://raw.githubusercontent.com/KyleSanderson/SteamWorks/master/Pawn/includes/SteamWorks.inc" -O include/SteamWorks.inc
wget "https://raw.githubusercontent.com/Flyflo/SM-Goomba-Stomp/master/addons/sourcemod/scripting/include/goomba.inc" -O include/goomba.inc
wget "https://forums.alliedmods.net/attachment.php?attachmentid=115795&d=1360508618" -O include/rtd.inc
wget "https://raw.githubusercontent.com/Phil25/RTD/master/scripting/include/rtd2.inc" -O include/rtd2.inc
wget "https://raw.githubusercontent.com/Silenci0/SMAC/master/addons/sourcemod/scripting/include/smac.inc" -O include/smac.inc
wget "https://raw.githubusercontent.com/Silenci0/SMAC/master/addons/sourcemod/scripting/include/smac_stocks.inc" -O include/smac_stocks.inc
wget "https://forums.alliedmods.net/attachment.php?attachmentid=116849&d=1377667508" -O include/tf2attributes.inc

sed -i'' 's/required = 1/#if defined REQUIRE_PLUGIN\nrequired = 1\n\#else\nrequired = 0/' include/rtd.inc