#pragma semicolon 1
#pragma newdecls required

public void InvalidEffect_Initialize(ChaosEffect effect)
{
	ThrowError("You forgot to define an effect class for '%T'!", effect.name, LANG_SERVER);
}
