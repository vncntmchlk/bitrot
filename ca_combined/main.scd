(
thisProcess.openUDPPort(9010);
~toBenni = NetAddr("10.42.0.171", 7401);
~localHost = NetAddr("127.0.0.1", 9001);
"../oscMidiEvent.scd".loadRelative;
"../ca_rhythm/resources.scd".loadRelative;
"resources_ca_fft.scd".loadRelative;
)




~game1 = ~newCaRhythm.((), prefix: "rhy1");
~game1Player = ~game1.spawner.play(quant: 2);
~game1Player.stop

~game2 = ~newCaRhythm.((), prefix: "rhy2");
~game2Player = ~game2.spawner.play(quant: 2);
~game2Player.stop
~game2.evPat = Pbind(
	\pulseSpeed, Pseq([1/8],inf),
	\steps, 4,
	\chan, 12,
	\midinote, 36
).asStream;
~game2.hitColor = \blue;


//die werte sollten am besten so skaliert werden, dass in den mittleren grauen bereichen am meisten aenderung ist
~gameFFT = ~caFFT.(16, 6);

Tdef(\fftBinsGainSmooth).play

~gameFFT.seedMe

Tdef(\fftBinsGainSmooth).stop

~gameFFT.relevantCa