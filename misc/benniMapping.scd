// ideen entwickeln welche parameter bzw parameterverknuepfungen wodurch gesteuert werden koennten
// CHECK-die fftBinsGain und Denoise durch die neuen CA. da der array nur 6 elemente hat evtl trotzdem groessere caSize aber nur einen ausschnitt davon benutzen ( die nicht benutzten teile abdunkeln?)
// das instrument auspacken und den kreiswinkel fuer einige parameter austesten, die gleichzeitig mit note onset geaendert werden
// optionen fuer mappings mit winkeln

// jeder kreis ein parameter von 0 bis 360
// > mögliches problem: zu schnelle änderung (wäre ja jeden "takt" durch die volle bandbreite einmal durch)

// alle kreise ändern den selben parameter
// entweder akkumulativ (0 bis 3 * 360)
// oder hin und her springend (koennte spannend sein mit unterschiedlichen kreis speeds)

// den original grain sequencer mit colSum auschecken, summe wiederum fuer db verwenden

n = NetAddr("192.168.178.69", 7401)

// Bitcrush Effekt mit 3 parametern
n.sendMsg("/bitrotData", "groupTrunc", 0.425) // 0 - 1 bittiefe
n.sendMsg("/bitrotData", "groupSRR", 0.225) // 0 - 1 sample rate reduction
n.sendMsg("/bitrotData", *(["xorBits"] ++ ([0, 0, 0, 0, 0, 0, 0, 0, 0, 0].scramble))) // 10 bit array bitflips

// fft brickwall effekt, 3 parameter
n.sendMsg("/bitrotData", "fftXbins", *[16, 32, 64, 128, 256]) // bins
n.sendMsg("/bitrotData", "fftBinsGain", *(0!6)) // -70 - 70 gain fuer jeweiliges Band
n.sendMsg("/bitrotData", "fftBinsDenoise", *(0!6)) // -100 bis 100 amp cutoff fuer jeweiliges Band

// granular sample looper 1 * 3 params plus freeze
n.sendMsg("/bitrotData", "grainStart_Looplength_Scanspeed", *[3000, 30, 100]) // grainstart in ms, looplength prozent 0 bis 100, scanspeed 0 bis 100
n.sendMsg("/bitrotData", "freeze", 0) //0 1

// instrumente per midi triggern, die zahl nach /notes ist die nummer vom instrument
// notes off muss auch geschickt werden
n.sendMsg("/notes0", 72, 100) // notes0 instrument1
n.sendMsg("/notes0", 72, 0) // notes0 instrument1 noteOff veloc 0 -- wichtig ..

// alle parameter gleichzeitig aendern
Pbind(
	\midinote, Pswitch1([
		Pstep([60,61,62,63],[1,1,1,1] * 1.5,inf),
		Pn(72)
	],Pseq([Pn(0,11),1],inf)).trace,
	\dur, Pwrand([1/8,1,3],[0.7,0.2,0.1],inf),
	\rest, Rest(1),
	\fftXbins, Pfunc{[16, 32, 64, 128, 256].scramble},
	\fftBinsGain, Pfunc{ 6.collect{ 22.0.rand} },
	\fftBinsDenoise, Pfunc{ 6.collect{ 52.0.rand * -1} },
	\grainStart_Looplength_Scanspeed, Pfunc { [500 + 3000.rand, 50.rand, 100.rand] },
	\freezeGrains, Pfunc { 2.rand },
	\xorBits, Pfunc{[1,1,0,0,0,0,0,0,0,0].scramble},
	\groupSRR, Pwhite(0,1),
	\groupTrunc,Pseq([0,0.5,1],inf),// Pn(Pgeom(0.1, 1.1, 20)),
	\finish, { |ev|
		n.sendMsg("/notes0",*[ev.midinote, 50 + 30.rand]);
		n.sendMsg("/bitrotData", "fftXbins", *ev.fftXbins);
		n.sendMsg("/bitrotData", "fftBinsGain", *ev.fftBinsGain);
		n.sendMsg("/bitrotData", "fftBinsDenoise", *ev.fftBinsDenoise);
		n.sendMsg("/bitrotData", "grainStart_Looplength_Scanspeed", *ev.grainStart_Looplength_Scanspeed);
		n.sendMsg("/bitrotData", "freeze", ev.freezeGrains);
		n.sendMsg("/bitrotData", "xorBits", *ev.xorBits);
		n.sendMsg("/bitrotData", "groupSRR", ev.groupSRR);
		n.sendMsg("/bitrotData", "groupTrunc", ev.groupTrunc.clip(0, 1))
	}
).play



(
// base pattern
p = Pbind(
	\midinote, Pswitch1([
		Pstep([60,61,62,63],[1,1,1,1] * 1.5,inf),
		Pn(72)
	],Pseq([Pn(0,11),1],inf)).trace,
	\amp, 0.1,
	\groupTrunc,Pseq([0,0.5,1],inf),// Pn(Pgeom(0.1, 1.1, 20)),
	\finish, { |ev|
		n.sendMsg("/bitrotData", "groupTrunc", ev.groupTrunc.clip(0, 1).postln)
	}
);
)

~a = 1;
x = PSPdiv(0.75, p, PL(\a)).play;
~a = [3,1];
~a = [5,2,1];
~a = PLseq([2, 3]);
~a = PLseq([2, 3,2,[3,1]]);

~a = PLseq([[3,6,12], 6,[8,4,2,1],2]);

x.stop