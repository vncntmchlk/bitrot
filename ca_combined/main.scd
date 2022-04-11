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

// roter buzzer fuer random massaker (von anfang das ding)
// noch ein kreis fuer zweite melodie
// und noch einer fuer sample sequencer (dann brauchst du auch nicht den link, theoretisch, aber egal trotzdem drin lassen weil es einfacher ist?)

//gaba preset: 10th und accelerando zu tempo clock 2.5, schnelle melodie kommt spaeter dazu

// sample loop sequencer
// pro loop geht der fft ca einen weiter (lastvals 0 usw.)
// ~toBenni = NetAddr("192.168.1.101", 7402); // PORT

// durchzappen, zb die sample 1 mit fft beats dings zu den magic dings hin und her duch kombinierte presets


(
thisProcess.openUDPPort(9010); // from open stage control
thisProcess.openUDPPort(9000); // from rpi
thisProcess.openUDPPort(9005); // from philipp
// ~toBenni = NetAddr("169.254.85.142", 7401);
~toBenni = NetAddr("192.168.1.102", 7402); // PORT
~localHost = NetAddr("127.0.0.1", 9001); // to open stage control
~rpiAddr = NetAddr("10.42.0.208", 9001);
~toPhilipp = NetAddr("192.168.1.104", 9004);//NetAddr("192.168.1.102", 9004);
// ~rpiAddr = NetAddr("169.254.167.159", 9001);
"manage_presets.scd".loadRelative;
"oscMidiEvent.scd".loadRelative;
"resources_rhythm.scd".loadRelative;
"resources_ca_fft.scd".loadRelative;
"resources_ca_bitflip.scd".loadRelative;
"resources_clip_launcher.scd".loadRelative;
~game1 = ~newCaRhythm.((), prefix: "rhy1");
~game2 = ~newCaRhythm.((), prefix: "rhy2");
~game2.hitColor = \blue;
~game2.evPatChan = 11;
~gameFFT = ~caFFT.(16, 6);
~gameBitFlip = ~caBitFlip.(16, 6);
// circle sequencer
"resources_circle.scd".loadRelative;
"gui_windows_circle.scd".loadRelative;
"cuePlan_to_gui.scd".loadRelative;
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
~toBenni.sendMsg("/clips", 1)
~toBenni.sendMsg("/clips", 3)
~toBenni.sendMsg("/cue", 3)

TempoClock.default.tempo = 1;

// wie kann man hier chan sinnvoll reinbringen?
// waere auch gut wenn es zb Pseq([11, 12],inf) moeglich waere

~circles.melodieCircle.presetManager[\savePreset].("cue11_erinnerung")
~circles.melodieCircle.presetManager[\showPresetDifference].("suesseMelodie2")
// ~circles.chordsCircle.presetManager[\savePreset].("basicOFF")
~circles.melodie2Circle.presetManager[\savePreset].("magic_arp")
~circles.bassCircle.presetManager[\savePreset].("basicOFF")
~gameFFT.presetManager[\savePreset].("soft_high")
~gameBitFlip.presetManager[\savePreset].("basicOFF")
~rhythmPM[\savePreset].("bitflip_linked_zerfressen")

~circles.melodieCircle.presetManager[\savePreset].("cue8_prep")

~circles.melodieCircle.presetManager[\savePreset].("simpleArp")


Tdef(\sampleLooper, {
	loop {
		~toBenni.sendMsg("/clips", 7);
		4.wait;
		Pdefn(\caFFTNext).asStream.next;
	}
}).play

~gameFFT.seedMe;
{~gameFFT.pointerToWindow.visible_(true)}.fork(AppClock);


Tdef(\sampleLooper, {
	loop {
		~toBenni.sendMsg("/clips", 7);
		2.wait;
		Pdefn(\caFFTNext).asStream.next;
	}
})
Tdef(\sampleLooper).stop
Tdef(\sampleLooper, {
	loop {
		~toBenni.sendMsg("/clips", 7);
		1.wait;
		Pdefn(\caFFTNext).asStream.next;
	}
})

Tdef(\sampleLooper, {
	loop {
		~toBenni.sendMsg("/clips", 7);
		0.25.wait;
		Pdefn(\caFFTNext).asStream.next;
	}
})

Tdef(\sampleLooper, {
	loop {
		~toBenni.sendMsg("/clips", 7);
		8.wait;
		// Pdefn(\caFFTNext).asStream.next;
	}
}).play