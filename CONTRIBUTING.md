## Issue Template:
**Title Prefixes:**
* `[Bug]`		A bug you may find, include error logs and the version
* `[Request]`		A feature you may want in the fork
* `[Suggestion]`	Non-code releated subject, usually do with GitHub itself
* `[Question]`		A question about the fork or the GitHub
* `[?]`			If your not sure which will fit the prefixes

*(If your issue has more than one, choice which seems apporitate)*

Rest of the title should be on it's about, introduction give a summary on what the issue is about.                       
Later, include any information you can about the subject, like current version or how it will improve.
***
## Pull Request Template:
**Title Prefixes:**
* `[Fix]`		A bug you may have fixed or a minor tweak
* `[Feature]`		A feature or enhancement to add in
* `[Major]`		The big pull requests, usually >1000 lines changed with both fixes and features
* `[Update]`		A update pull request, usually directed to master branch

*(If none of these fit, it's alright)*

Rest of the title should be what it adds/fixes, give off information on why it should be added.                              
If there are mistakes, we can resolve them, no need to close and make a new one later.                                  
**Pull requests should go to development branch and NEVER master branch!**
***
## Pull Request Formatting Example:
```sourcepawn
#define DEFINESUSEALLCAPS	"Tabs!"

bool GlobalVariable;

public Action OnThisEvent(Handle localHandle, int &localInt, const char[] localString)
{
	if(localHandle == INVALID_HANDLE)
		return Plugin_Handled;

	if(strlen(localString) && StringToInt(localString)==localInt)	// Commment have tabs
	{
		char localString2[64];
		switch(localInt)
		{
			case 2:
				strcopy(localString2, sizeof(localString2), "Small Example");

			case 5:
				localInt = 3;

			default:
				localInt--;
		}

		for(int i; i<5; i++)
		{
			localInt--;
		}

		float yes;
		switch(localInt)
		{
			case 2:
			{
				strcopy(localString2, sizeof(localString2), "Large Example");
				yes = (5.0/localInt) + 2.1;
			}
			case 7:
			{
				yes = 2.6 - float(localInt);
			}
			default:
			{
				strcopy(localString2, sizeof(localString2), DEFINESUSEALLCAPS);
			}
		}

		while(localInt > 0)
		{
			localInt--;
			yes += 1.3;
		}
		return yes>5 ? Plugin_Stop : Plugin_Continue;
	}

	if(localInt < 0)
		return Plugin_Continue;

	localInt++;
	GlobalVariable = true;
	return Plugin_Continue; 
}
```
***
### Thank you for reading and contributing to the repository
