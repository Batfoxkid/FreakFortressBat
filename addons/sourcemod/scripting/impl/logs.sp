enum struct FF2LogsPaths_t
{
    char Bosses[PLATFORM_MAX_PATH];
    char Errors[PLATFORM_MAX_PATH];
    char Round[PLATFORM_MAX_PATH];

    void Init()
    {
        BuildPath(Path_SM, this.Bosses, sizeof(FF2LogsPaths_t::Bosses), BossLogPath);
        if(!DirExists(this.Bosses))
        {
            if(!CreateDirectory(this.Bosses, 511))
                LogError("Failed to create directory at %s", this.Bosses);
        }

        BuildPath(Path_SM, this.Errors, sizeof(FF2LogsPaths_t::Errors), "%s/%s", LogPath, ErrorLog);
        if(!FileExists(this.Errors))
            OpenFile(this.Errors, "a+");
    }

    void WriteRoundInfo(const char[] boss_name, const char[] time, const char[] player_name, const char[] authId, const char[] result)
    {
        char log_dir[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, log_dir, sizeof(log_dir), "%s/%s.txt", BossLogPath, boss_name);
        File bossLog = OpenFile(log_dir, "a+");
        if(bossLog)
        {
            bossLog.WriteLine("%s on %s - %s <%s> has %s", time, FF2Globals.CurrentMap, player_name, authId, result);
            bossLog.WriteLine("");
            delete bossLog;
		}
    }
}
FF2LogsPaths_t FF2LogsPaths;