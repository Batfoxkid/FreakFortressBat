enum struct FF2Huds_t
{
	Handle Jump;
	Handle Rage;
	Handle Lives;
	Handle TimeLeft;
	Handle Abilities;
	Handle PlayerInfo;
	Handle PlayerStat;
	Handle Health;
	Handle Rival;

    void Init()
    {
        this.Jump = CreateHudSynchronizer();
        this.Rage = CreateHudSynchronizer();
        this.Lives = CreateHudSynchronizer();
        this.Abilities = CreateHudSynchronizer();
        this.TimeLeft = CreateHudSynchronizer();
        this.PlayerInfo = CreateHudSynchronizer();
        this.PlayerStat = CreateHudSynchronizer();
        this.Health = CreateHudSynchronizer();
        this.Rival = CreateHudSynchronizer();
    }
}
FF2Huds_t FF2Huds;