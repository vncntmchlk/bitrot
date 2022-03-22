// rpi starten ssh pi@raspberrypi.local

// ip adressen die richtig eingestellt sein muessen:
// vm -> rpi, rpi -> vm
// vm -> benni
// vm -> philipp, philipp -> vm

// formteile
// atmo, durch ca geschmeidig geaendert
// aenderung wird ruckartig
// dann kommen drum die das uebernehmen
// dann atmo raus

// drums mit delay und grains, tempo geht auch sehr schnell

// kreissequenzer:
// quant bzw quantVal wird verabschiedet.
// es wird jetzt nur durch dur und speedfaktor bestimmt (8, 1, fuer sechzehntel quantisierung)


(
thisProcess.openUDPPort(9010); // from open stage control
thisProcess.openUDPPort(9000); // from rpi
thisProcess.openUDPPort(9005); // from philipp
~toBenni = NetAddr("169.254.85.142", 7401);
// ~toBenni = NetAddr("192.168.1.100", 7401);
~localHost = NetAddr("127.0.0.1", 9001); // to open stage control
~rpiAddr = NetAddr("10.42.0.208", 9001);
~toPhilipp = NetAddr("127.0.0.1", 6666);//NetAddr("192.168.1.102", 9004);
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
// ~rpiAddr.sendMsg("/circles", 1);
)

// um aktuelle window konfiguration zu kriegen:
~circles.guiElements.melodieWindow.bounds.origin;
~circles.guiElements.bassWindow.bounds.origin;
~circles.guiElements.chordsWindow.bounds.origin;
// USW

~rpiAddr.sendMsg("/circles", 0);
~rpiAddr.sendMsg("/circles", 1);

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

~presetManager[\showPresetDifference].("aaa")

