static GlobalForward fwdPreAbility;
static GlobalForward fwdOnAbility;
static GlobalForward fwdOnMusic;
static GlobalForward fwdOnMusic2;
static GlobalForward fwdOnTriggerHurt;
static GlobalForward fwdOnSpecialSelected;
static GlobalForward fwdOnAddQueuePoints;
static GlobalForward fwdOnLoadCharacterSet;
static GlobalForward fwdOnLoseLife;
static GlobalForward fwdOnAlivePlayersChanged;
static GlobalForward fwdOnBackstabbed;

void Forwards_Create()
{
    fwdPreAbility = new GlobalForward("FF2_PreAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);  //Boss, plugin name, ability name, slot, enabled
    fwdOnAbility = new GlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);  //Boss, plugin name, ability name, status
    fwdOnMusic = new GlobalForward("FF2_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
    fwdOnMusic2 = new GlobalForward("FF2_OnMusic2", ET_Hook, Param_String, Param_FloatByRef, Param_String, Param_String);
    fwdOnTriggerHurt = new GlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
    fwdOnSpecialSelected = new GlobalForward("FF2_OnSpecialSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String, Param_Cell);  //Boss, character index, character name, preset
    fwdOnAddQueuePoints = new GlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
    fwdOnLoadCharacterSet = new GlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_CellByRef, Param_String);
    fwdOnLoseLife = new GlobalForward("FF2_OnLoseLife", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);  //Boss, lives left, max lives
    fwdOnAlivePlayersChanged = new GlobalForward("FF2_OnAlivePlayersChanged", ET_Hook, Param_Cell, Param_Cell);  //Players, FF2Globals.Bosses
    fwdOnBackstabbed = new GlobalForward("FF2_OnBackStabbed", ET_Hook, Param_Cell, Param_Cell, Param_Cell);  //Boss, client, attacker
}

void Forwards_Call_PreAbility(
    int boss,
    const char[] plugin_name,
    const char[] ability_name,
    int slot,
    bool& enabled
)
{
	Call_StartForward(fwdPreAbility);
	Call_PushCell(boss);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	Call_PushCell(slot);
	Call_PushCellRef(enabled);
	Call_Finish();
}

void Forwards_BeginCall_OnAbility(
    int boss,
    const char[] plugin_name,
    const char[] ability_name
)
{
	Call_StartForward(fwdOnAbility);
	Call_PushCell(boss);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
}

Action Forwards_EndCall_OnAbility(
    int status
)
{
    Action res;
    Call_PushCell(status);
    Call_Finish(res);
    return res;
}

Action Forwards_Call_OnMusic(
    char[] music,
    int size_of_music,
    float& time
)
{
    Action res;
    Call_StartForward(fwdOnMusic);
    Call_PushStringEx(music, size_of_music, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushFloatRef(time);
    Call_Finish(res);
    return res;
}

Action Forwards_Call_OnMusic2(
    char[] music,
    float& time,
    char[] name,
    char[] artist,
    int size_of_buffers
)
{
    Action res;
    Call_StartForward(fwdOnMusic2);
    Call_PushStringEx(music, size_of_buffers, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushFloatRef(time);
    Call_PushStringEx(name, size_of_buffers, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushStringEx(artist, size_of_buffers, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_Finish(res);
    return res;
}

Action Forwards_Call_OnTriggerHurt(
    int boss,
    int attacker,
    float& damage
)
{
    Action res;
    Call_StartForward(fwdOnTriggerHurt);
    Call_PushCell(boss);
    Call_PushCell(attacker);
    Call_PushFloatRef(damage);
    Call_Finish(res);
    return res;
}

Action Forwards_Call_OnCharSelected(
    int boss,
    int& char_index,
    char[] new_name,
    int size_of_new_name,
    bool is_preset
)
{
    Action res;
    Call_StartForward(fwdOnSpecialSelected);
    Call_PushCell(boss);
    Call_PushCellRef(char_index);
    Call_PushStringEx(new_name, size_of_new_name, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(is_preset);  //Preset
    Call_Finish(res);
    return res;
}

Action Forwards_Call_OnAddQueuePoints(
    int[] points_to_add
)
{
    Action res = Plugin_Continue;
    Call_StartForward(fwdOnAddQueuePoints);
    Call_PushArrayEx(points_to_add, MaxClients + 1, SM_PARAM_COPYBACK);
    Call_Finish(res);
    return res;
}

Action Forwards_Call_OnLoadCharSet(
    int& num_of_charset,
    char[] charset,
    int size_of_charset
)
{
    Action res = Plugin_Continue;
    Call_StartForward(fwdOnLoadCharacterSet);
    Call_PushCellRef(num_of_charset);
    Call_PushStringEx(charset, size_of_charset, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_Finish(res);
    return res;
}

Action Forwards_Call_OnLoseLife(
    int boss,
    int& boss_lives,
    int boss_max_lives
)
{
    Action res;
    Call_StartForward(fwdOnLoseLife);
    Call_PushCell(boss);
    Call_PushCellRef(boss_lives);
    Call_PushCell(boss_max_lives);
    Call_Finish(res);
    return res;
}

void Forwards_Call_AlivePlayersCountChanged(
    int mercs_count,
    int boss_count
)
{
	Call_StartForward(fwdOnAlivePlayersChanged);  //Let subplugins know that the number of alive players just changed
	Call_PushCell(mercs_count);
	Call_PushCell(boss_count);
	Call_Finish();
}

Action Forwards_Call_OnBackstabbed(
    int boss,
    int client,
    int attacker
)
{
    Action res;
    Call_StartForward(fwdOnBackstabbed);
    Call_PushCell(boss);
    Call_PushCell(client);
    Call_PushCell(attacker);
    Call_Finish(res);
    return res;
}