var prefix = "gui";
~guiAll = ();
~guiAll.sharedEv = OSCSharedEvent.new(~localHost, prefix);
~guiAll.sharedEv.scopeOnOff = 0;
~guiAll.sharedEv.specBigOnOff = 0;
~guiAll.sharedEv.specSmallOnOff = 0;
~guiAll.sharedEv.makeOSCdefsForKeys((
	scopeOnOff: (~scopeGUI[\onOff].(_)),
	specBigOnOff: (~spectograms.big[\onOff].(_)),
	specSmallOnOff: (~spectograms.small[\onOff].(_))
));
~guiAll.sharedEv.sendAll;
~guiAll.pm = ~makePresetManagerGUI.(prefix,
	["~guiAll.pm.positions","~scopeGUI.options","~guiAll.sharedEv"]
);




//change these while the program is running
/*~scopeGUI.options.sample= 2;
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
~scopeGUI.options.version = 2;*/
