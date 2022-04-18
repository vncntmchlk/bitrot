// rpi starten ssh pi@raspberrypi.local

// ip adressen die richtig eingestellt sein muessen:
// vm -> rpi, rpi -> vm
// vm -> benni
// vm -> philipp, philipp -> vm

// roter buzzer fuer random massaker (von anfang das ding)

//gaba preset: 10th und accelerando zu tempo clock 2.5, schnelle melodie kommt spaeter dazu

// cues ausmisten, fuer die rhythmen gute einstellungen finden. jedesmal wenn ein instrument oder fx dazukommt einen cue dafuer haben


~toBenni = NetAddr("192.168.1.101", 7401); // PORT
// bei 21 clicks hoerbar????
// bei gaba bass auf 10er vorher
// anfang ueben und fft tiefe einbauen
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

~tempoSharedEv = OSCSharedEvent.new(~localhost);
~tempoSharedEv.tempo = 1;
~tempoSharedEv.makeOSCdefsForKeys((
	tempo: { |val|
		TempoClock.default.tempo = val;
	}
));
~buzzerStuff.resetValues;
// ~rpiAddr.sendMsg("/circles", 1);
)

~rpiAddr.sendMsg("/circles", 0);
~rpiAddr.sendMsg("/circles", 1);


TempoClock.default.tempo = 1;

~circles.melodieCircle.presetManager[\savePreset].("C16_homophon")
~circles.melodie2Circle.presetManager[\savePreset].("accelZusammen")
~circles.bassCircle.presetManager[\loadPreset].("benniSolo")


~circles.melodieCircle.presetManager[\savePreset].("C34_M1_M2_sync")
~circles.melodieCircle.presetManager[\showPresetDifference].("suesseMelodie2")
~circles.melodie2Circle.presetManager[\savePreset].("C34_M1_M2_sync")
~circles.bassCircle.presetManager[\savePreset].("benniSolo")
~gameFFT.presetManager[\savePreset].("C29_waves")
~gameBitFlip.presetManager[\savePreset].("C38_softRule6")
~rhythmPM[\savePreset].("C28_q10Clicks")

~circles.melodieCircle.presetManager[\savePreset].("cue8_prep")

~circles.melodieCircle.presetManager[\savePreset].("simpleArp")

