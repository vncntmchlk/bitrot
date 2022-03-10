//mit bennis sounds testen

// anschliessend diese und das fft ca gleichzeitig bedienen
(
~toBenni = NetAddr("10.42.0.171", 7401);
"../oscMidiEvent.scd".loadRelative;
"resources.scd".loadRelative;
)


~rhyPlayer = ~caRhy.spawner.play

~rhyPlayer.stop
x = Pbind(
	\dur, 1/8,
	\instrument, \no,
	\type, \oscMidi,
	\amp, Pwhite(0.1,0.9),
	\chan, 13,
	\midinote,36,
	// \db, -50,
	\netAddr, ~toBenni
).play
x.stop

x = Pbind(
	\dur, 1/2,
	\instrument, \no,
	\type, \oscMidi,
	\amp, Pwhite(0.1,0.9),
	\chan, 11,
	\midinote,36,
	// \db, -50,
	\netAddr, ~toBenni
).play