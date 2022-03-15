// rpi starten ssh pi@raspberrypi.local
(
"resources.scd".loadRelative;
"gui_windows.scd".loadRelative;
"oscDefs.scd".loadRelative;
)
~mOut = ConnectVirmidi(0); // fuer jetzt zum testen
// um video feed zu empfangen
"python ~/Repos/self-assemblers/rec_images.py".runInTerminal;

/// CIRCLES
~rpiAddr.sendMsg("/circles", 1); // on / off befehl fuer die osc msgs vom rpi
~rpiAddr.sendMsg("/circles", 0);
Tdef(\circ0).play(doReset: true, quant: [1,0,-0.025]);
Tdef(\circ0).stop
/*
Tdef(\circ0).play(doReset: true, quant: [1,0,-0.025]);
Tdef(\circ1).play(doReset: true, quant: [1,0,-0.025]);
Tdef(\circ2).play(doReset: true, quant: [1,0,-0.025]);

Tdef(\circ3).play(doReset: true, quant: [1,0,-0.025]);
Tdef(\circ4).play(doReset: true, quant: [1,0,-0.025]);
Tdef(\circ5).play(doReset: true, quant: [1,0,-0.025]);
~oscPresets.savePreset("x")
~oscPresets.loadPreset("slowDrums")*/

// ~mOut = ConnectVirmidi(0);
// ~mOut.noteOn(0, 36, 100)