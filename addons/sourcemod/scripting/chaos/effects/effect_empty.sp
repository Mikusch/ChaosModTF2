#pragma semicolon 1
#pragma newdecls required

public bool InvalidEffect_Initialize(ChaosEffect effect)
{
	LogError("You forgot to define an effect class for '%T'!", effect.name, LANG_SERVER);
	
	return false;
}
