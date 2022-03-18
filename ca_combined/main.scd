// rpi starten ssh pi@raspberrypi.local

// ip adressen die richtig eingestellt sein muessen:
// vm -> rpi, rpi -> vm
// vm -> benni
// vm -> philipp, philipp -> vm

// zu philipp nur einmal pro index schicken (und zu benni auch?)
// chords und bass kreis, damit man alle separat einfrieren kann
// damit philipp direkt die noten aendern kann:
// zuerst wird ihm der index geschickt
// einen index spaeter wird der abgespielt (offset von abspielen und auslesen)

// formteile
// atmo, durch ca geschmeidig geaendert
// aenderung wird ruckartig
// dann kommen drum die das uebernehmen
// dann atmo raus

// drums mit delay und grains, tempo geht auch sehr schnell



(
thisProcess.openUDPPort(9010); // from open stage control
thisProcess.openUDPPort(9000); // from rpi
thisProcess.openUDPPort(9005); // from philipp
// ~toBenni = NetAddr("10.42.0.171", 7401);
~toBenni = NetAddr("192.168.1.100", 7401);
~localHost = NetAddr("127.0.0.1", 9001); // to open stage control
~rpiAddr = NetAddr("10.42.0.208", 9001);
~toPhilipp = NetAddr("192.168.1.102", 9004);
OSCdef(\philippMelody, {|msg|
	// msg.postln;
	if(msg[1..].size == 16){
		~melodie = msg[1..];
	}
}, "/melodyList").fix;

OSCdef(\philippBassLine, {|msg|
	// msg.postln;
	if(msg[1..].size == 16){
		~bassLine = msg[1..];
	}
}, "/bassList").fix;

// ~rpiAddr = NetAddr("169.254.167.159", 9001);
"../oscMidiEvent.scd".loadRelative;
"../ca_rhythm/resources.scd".loadRelative;
"resources_ca_fft.scd".loadRelative;
"resources_ca_bitflip.scd".loadRelative;
"manage_presets.scd".loadRelative;
~game1 = ~newCaRhythm.((), prefix: "rhy1");
~game2 = ~newCaRhythm.((), prefix: "rhy2");
~gameFFT = ~caFFT.(16, 6);
~gameBitFlip = ~caBitFlip.(16, 6);
// circle sequencer
"../circle_sequencer/resources.scd".loadRelative;
"../circle_sequencer/gui_windows.scd".loadRelative;
)

~toBenni.sendMsg("/clips", 0)
~toBenni.sendMsg("/bitrotData", "fftBinsGain", *(0!6)) // -70 - 70 gain fuer jeweiliges Band

~game2.evPatChan = 11
TempoClock.default.tempo = 1;

~game2Player = ~game2.spawner.play(quant: 2);
~game2Player.stop
~game2.evPat = Pbind(
	\pulseSpeed, Pseq([1/8],inf),
	\steps, 4,
	\chan, 11,
	\midinote, 36
).asStream;
~game2.hitColor = \blue;
// wie kann man hier chan sinnvoll reinbringen?
// waere auch gut wenn es zb Pseq([11, 12],inf) moeglich waere

~presetManager[\savePreset].([
	"~game1.sharedEv",
	"~game2.sharedEv",
	"~gameFFT.sharedEv",
	"~gameBitFlip.sharedEv"
], "aaa")
~presetManager[\loadPreset].("aaa")
