#pragma semicolon 1
#pragma newdecls required

public void Earthquake_Update(ChaosEffect effect)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageAll("Shake"));
	bf.WriteByte(0);
	bf.WriteFloat(10.0);
	bf.WriteFloat(150.0);
	bf.WriteFloat(1.0);
	EndMessage();
}
