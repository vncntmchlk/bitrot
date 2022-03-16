// rpi starten ssh pi@raspberrypi.local

(
thisProcess.openUDPPort(9010); // from open stage control
thisProcess.openUDPPort(9000); // from rpi
// ~toBenni = NetAddr("10.42.0.171", 7401);
~toBenni = NetAddr("169.254.85.142", 7401);
~localHost = NetAddr("127.0.0.1", 9001); // to open stage control
~rpiAddr = NetAddr("10.42.0.208", 9001);
"../oscMidiEvent.scd".loadRelative;
"../ca_rhythm/resources.scd".loadRelative;
"resources_ca_fft.scd".loadRelative;
"resources_ca_bitflip.scd".loadRelative;
// circle sequencer
"../circle_sequencer/resources.scd".loadRelative;
"../circle_sequencer/gui_windows.scd".loadRelative;
)
//
~rpiAddr.sendMsg("/circles", 1); // on / off befehl fuer die osc msgs vom rpi
~rpiAddr.sendMsg("/circles", 0);

TempoClock.default.tempo = 0.75;

~game1 = ~newCaRhythm.((), prefix: "rhy1");
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

~gameBitFlip = ~caBitFlip.(16, 6);



