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

// ~rpiAddr.sendMsg("/circles", 1);
)

// um aktuelle window konfiguration zu kriegen:
~circles.guiElements.melodieWindow.bounds.origin;
~circles.guiElements.bassWindow.bounds.origin;
~circles.guiElements.chordsWindow.bounds.origin;
// USW
Tdef(("circ0").asSymbol).quant
~rpiAddr.sendMsg("/circles", 0);
~rpiAddr.sendMsg("/circles", 1);

~toBenni.sendMsg("/clips", 0)
~toBenni.sendMsg("/clips", 1)
~toBenni.sendMsg("/clips", 2)

TempoClock.default.tempo = 1;

// wie kann man hier chan sinnvoll reinbringen?
// waere auch gut wenn es zb Pseq([11, 12],inf) moeglich waere

~circles.melodieCircle.presetManager[\savePreset].("suesseMelodie3")
~circles.melodieCircle.presetManager[\showPresetDifference].("suesseMelodie2")
~circles.chordsCircle.presetManager[\savePreset].("basicOFF")
~circles.bassCircle.presetManager[\savePreset].("basicOFF")
~gameFFT.presetManager[\savePreset].("soft_high")
~gameBitFlip.presetManager[\savePreset].("basicOFF")
~rhythmPM[\savePreset].("10th")

~circles.melodieCircle.presetManager[\savePreset].("simpleMath")