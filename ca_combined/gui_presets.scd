// preset speichern:
// alle aktuellen positionen, sowie scope einstellungen und evtl noch andere wie CA size werden gespeichert
// preset name wird zu osc geschickt

// preset laden:
// alle ... werden geladen

~guiAll = ();
~guiAll.pm = ~makePresetManagerGUI.("gui",["~guiAll.pm.positions","~scopeGUI.options"]);


~guiAll.pm[\savePreset].("useless2");


~scopeGUI.win.visible_(true)

//change these while the program is running
~scopeGUI.options.sample= 2;
~scopeGUI.options.sample= 10;
~scopeGUI.options.sample= 1;
~scopeGUI.options.trails= 1
~scopeGUI.options.speed= 0.01;
~scopeGUI.options.speed= 0;
~scopeGUI.options.trails= 0.01;
~scopeGUI.options.amp= 0.45;
~scopeGUI.options.speed= pi*0.25;
~scopeGUI.options.amp= 2;
~scopeGUI.options.sample= 2;
~scopeGUI.options.version= 0;
~scopeGUI.options.trails= 0.2;
~scopeGUI.options.version= 2;
~scopeGUI.options.sample= 1;
~scopeGUI.options.version= 2;
~scopeGUI.options.speed= 2pi*1.001;
~scopeGUI.options.amp= 0.1;
~scopeGUI.options.trails = 0.15
//schoen mit SRR
~scopeGUI.options.trails = 1;
~scopeGUI.options.speed = 0.1;
~scopeGUI.options.sample = 2;
~scopeGUI.options.amp = 1;
~scopeGUI.options.version = 2;
a = Spectrogram.new;
a.start;
{SoundIn.ar([4, 5])}.play
