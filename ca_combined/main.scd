// loops (bzw. methode finden wie ich es als instrument bedienen kann)
// alle relevanten parameter in die gui noch (pulsespeed zb, on off (play))
// kreissequencer (synchronisiert) melodie bass, chords
// bitflip CA mit wirkungsbereich (koennte interessant sein wie ca FFT, aber die colSums mit round(1) auf 0 oder 1 forcieren). vielleicht gehts dann sogar gut mit vielen lastValues
// einen link drum CA mit fft ca fortschreitung
// bei dem fft ca showOnly mit auswirkung auf wieviele bins gesendet werden (fuer die die nicht gesendet werden 0 oder -inf einfuegen)

(
thisProcess.openUDPPort(9010);
~toBenni = NetAddr("10.42.0.171", 7401);
~localHost = NetAddr("127.0.0.1", 9001);
"../oscMidiEvent.scd".loadRelative;
"../ca_rhythm/resources.scd".loadRelative;
"resources_ca_fft.scd".loadRelative;
"resources_ca_bitflip.scd".loadRelative;
)

~game1 = ~newCaRhythm.((), prefix: "rhy1");
Pdef(\rhy1spawner).play(quant: 1)
Pdef(\rhy1spawner).stop

~game1.evPat = Pbind(
	\loopOnOff, Pseq([false, true, true, true], inf),
	\pulseSpeed, Pseq([1/8],inf),
	\steps, 4,
	\chan, 13,
	\midinote, 36
).asStream;
/*~game1.pbindChain = Pbind(
\callFunc, Pfunc{|ev| if(ev.amp > 0){Pdefn(\caFFTNext).asStream.next};0}
)
~game1.pbindChain = Pbind()*/
~game1.evPat = Pbind(
	\pulseSpeed, Pseq([1/8],inf),
	\steps, 8,
	\chan, 13,
	\midinote, 36
).asStream;


~game2 = ~newCaRhythm.((), prefix: "rhy2");
~game2Player = ~game2.spawner.play(quant: 2);
~game2Player.stop
~game2.evPat = Pbind(
	\pulseSpeed, Pseq([1/8],inf),
	\steps, 4,
	\chan, 11,
	\midinote, 36
).asStream;
~game2.hitColor = \blue;


//die werte sollten am besten so skaliert werden, dass in den mittleren grauen bereichen am meisten aenderung ist
~gameFFT = ~caFFT.(16, 6);

Tdef(\fftBinsGainSmooth).play

~gameFFT.seedMe
// ~gameFFT.onlyShow([0,5])

Tdef(\fftBinsGainSmooth).stop

~gameFFT.relevantCa

~gameBitFlip = ~caBitFlip.(16, 6);


~click = Pbind(
	\dur, 1,
	\instrument, \no,
	\type, \oscMidi,
	\amp, Pseq([0.5, 0.2], inf),
	\chan, 13,
	\midinote, 36,
	\netAddr, ~toBenni
).play(quant: 2);


x = Pbind(
	\type, \oscMidi,
	\dur, 1/8,
	\chan, 0,
	\netAddr, ~toBenni,
	\index, Pseq((0..15),inf),
	\midinote, Pfunc{|ev| ~melodie[ev.index] }, //PLseq(\melodie),
	\amp, PLseq(\rhy),
	\finish, {|ev|
		topEnvironment[\toPhilipp].sendMsg("/index", (ev.index + 1).mod(16));
		ev
	}
).play(quant: 2)


x.stop
~click.stop



~manuellWeiter = Routine{
	var lastColSums = 0 ! ~sharedEvFFT.caSize;
	var nextColSums;
	var sendDb;
	var dbArr = [
		[0, 6],
		[0, 5],
		[0, 4],
		[0, 3],
		[0, 2],
		[0, 1]
	];
	var emphasizeMidSection = Env.new([0,0.5,1],[0.5,0.5],[5, -5]);
	loop {
		var blendSteps = ~sharedEvFFT.blendSteps;
		var sendRate = ~sharedEvFFT.sendRate; // Hz
		~gameFFT.nextGen;
		sendDb = ~gameFFT.colSums[~gameFFT.relevantCa[0]..(~gameFFT.relevantCa[1] - 1)].collect {|v, ix|
			v = emphasizeMidSection[v];
			v.linlin(0, 1, dbArr[ix][0], dbArr[ix][1])
		};
		~toBenni.sendMsg("/bitrotData", "fftBinsMin", *sendDb);
		1.yield
	}
}

~manuellWeiter.next

