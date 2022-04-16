// rpi starten ssh pi@raspberrypi.local

// ip adressen die richtig eingestellt sein muessen:
// vm -> rpi, rpi -> vm
// vm -> benni
// vm -> philipp, philipp -> vm

// roter buzzer fuer random massaker (von anfang das ding)

//gaba preset: 10th und accelerando zu tempo clock 2.5, schnelle melodie kommt spaeter dazu

// durchzappen, zb die sample 1 mit fft beats dings zu den magic dings hin und her duch kombinierte presets

~toBenni = NetAddr("192.168.1.101", 7401); // PORT

// bei 22 clicks und clips aus, melodie 1 auch
// die links duerfen nicht gegenseitig die windows ausschalten, brauch ein globas set oder so

// block or pass quantisiert aendern bei den fft loechern
// topEnvironment[\toBenni].sendMsg("/bitrotData", "fftXbins", *[16, 32, 64, 128, 256]);
bei 22 ein kombinierten cue der alles umschaltet
(
~guiBorder = true;
~guiBackgroundColor = Color.grey(0, 0); // Color.grey(0, 0);
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
// "resources_scope.scd".loadRelative;
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
~tempoSharedEv = OSCSharedEvent.new(~localhost);
~tempoSharedEv.tempo = 1;
~tempoSharedEv.makeOSCdefsForKeys((
	tempo: { |val|
		TempoClock.default.tempo = val;
	}
));
~buzzerStuff.resetValues
)


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

~circles.melodieCircle.presetManager[\savePreset].("accelZusammen")
~circles.melodie2Circle.presetManager[\savePreset].("accelZusammen")
~circles.bassCircle.presetManager[\loadPreset].("benniSolo")


~circles.melodieCircle.presetManager[\savePreset].("kuckkucksNest")
~circles.melodieCircle.presetManager[\showPresetDifference].("suesseMelodie2")
// ~circles.chordsCircle.presetManager[\savePreset].("basicOFF")
~circles.melodie2Circle.presetManager[\savePreset].("magic_arp")
~circles.bassCircle.presetManager[\savePreset].("benniSolo")
~gameFFT.presetManager[\savePreset].("shredding")
~gameBitFlip.presetManager[\savePreset].("shredRegular")
~rhythmPM[\savePreset].("shredding")

~circles.melodieCircle.presetManager[\savePreset].("cue8_prep")

~circles.melodieCircle.presetManager[\savePreset].("simpleArp")

