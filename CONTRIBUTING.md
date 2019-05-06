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
#define TABS  true

#define SpacesForTheUnbalanced 1
#define OrWhatLooksNice 3

#define FLAG1	(1<<1)
#define FLAG2	(1<<2)
#define FLAG3	(1<<3)

bool Yes = true;
int No;
int AlsoGood;
char forLocalVariables[64];
Handle NOGOOD;
float notgood;

public Action OnThisEvent(Handle NOGOOD, int Switches)
{
	if(NOGOOD==INVALID_HANDLE)
		return Plugin_Handled;
	/*
		Long comments
	*/
	if(Yes)	// Commment tabs
	{
		char maybe[64];	// Assign when needed

		if(No == 3)
		{
			switch(Switches)
			{
				case 2:
					maybe='No brackets needed';

				case 5:
					maybe='Needed for multiple things';

				default:
					maybe='\0';
			}

			for(int forLoop=1; forLoop<OrWhatLooksNice; forLoop++)
			{
				No--;
			}
// No tabs here
			AlsoGood |= FLAG1|FLAG3;
		}
		return maybe;
	}
	else if(strlen(forLocalVariables) || notgood!=0)
	{
		No++;
	}
	return Plugin_Continue; 
}

#file "Formatting Example for Pull Requests"

#error "Your not supposed to compile this boio"
```
***
### Thank you for reading and contributing to the repository
