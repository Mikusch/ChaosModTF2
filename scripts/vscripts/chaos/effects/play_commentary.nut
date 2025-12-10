function ChaosEffect_OnStart()
{
	local sound = format("commentary/tf2-comment%03d.mp3", RandomInt(0, 48))
	PrecacheSound(sound)
	EmitSoundEx({ sound_name = sound, channel = CHAN_STATIC })
}