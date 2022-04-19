var presetFolderPath = PathName(thisProcess.nowExecutingPath).pathOnly  ++ "presets";

~makePresetManager = { |pmName, evNames|
	var pm = (
		presetPath: presetFolderPath +/+ pmName,
		existingPresets: {
			PathName(pm.presetPath).files.collect {|file| file.fileNameWithoutExtension}.sort
		},
		savePreset: {|name = "test"|
			var preset = ();
			evNames.do { |str|
				preset[str.asSymbol] = str.interpret.as(Dictionary); // vom OSCSharedEvent umwandeln
			};
			preset.writeArchive(pm.presetPath +/+ name ++ ".preset");
			{pm.sendPresetsToOSC}.defer(0.5); // dropdown aktualisieren
		},
		loadPreset: {|name = "test"|
			var preset = Object.readArchive(pm.presetPath +/+ name ++ ".preset");
			preset.keysValuesDo {|str, ev|
				ev.pairsDo {|k, v|
					var currentVal = (str ++ "['" ++ k ++ "']").interpret;
					if(currentVal != v){
						(str ++ "['" ++ k ++ "'] = " ++ v).interpret
					}
				}
			}
		},
		showPresetDifference: {|name = "test"|
			var preset = Object.readArchive(pm.presetPath +/+ name ++ ".preset");
			preset.keysValuesDo {|str, ev|
				ev.pairsDo {|k, v|
					var currentVal = (str ++ "['" ++ k ++ "']").interpret;
					if(currentVal != v){
						(str ++ "." ++ k).postln;
						("" ++ currentVal ++ " --> " ++ v).postln;
					}
				}
			}
		},
		sendPresetsToOSC: {
			var presetsJSON = Dictionary.new();
			presetsJSON[\values] = Dictionary.new();
			pm.existingPresets.do {|sym|
				presetsJSON[\values][sym] = sym
			};
			~localHost.sendMsg("/EDIT", pmName +/+ "loadPreset", JSON.stringify(presetsJSON))
		}
	);
	OSCdef((pmName ++ "loadPreset").asSymbol, {|msg|
		pm[\loadPreset].(msg[1]);
	}, "/" ++ pmName +/+ "loadPreset").fix;

	OSCdef((pmName ++ "updatePreset").asSymbol, {|msg|
		("updating " ++ msg[1]).postln;
		pm[\savePreset].(msg[1]);
	}, "/" ++ pmName +/+ "updatePreset").fix;

	pm.sendPresetsToOSC;
	pm
};


// fuer gui presets ...
~makePresetManagerGUI = { |pmName, evNames|
	var pm = (
		presetPath: presetFolderPath +/+ pmName,
		existingPresets: {
			PathName(pm.presetPath).files.collect {|file| file.fileNameWithoutExtension}.sort
		},
		savePreset: {|name = "test"|
			var preset = ();
			pm.getPositions;
			evNames.do { |str|
				preset[str.asSymbol] = str.interpret.as(Dictionary); // vom OSCSharedEvent umwandeln
			};
			preset.writeArchive(pm.presetPath +/+ name ++ ".preset");
			{pm.sendPresetsToOSC}.defer(0.5); // dropdown aktualisieren
		},
		loadPreset: {|name = "test"|
			var preset = Object.readArchive(pm.presetPath +/+ name ++ ".preset");
			preset.keysValuesDo {|str, ev|
				ev.pairsDo {|k, v|
					var currentVal = (str ++ "['" ++ k ++ "']").interpret;
					if(currentVal != v){
						(str ++ "['" ++ k ++ "'] = " ++ v).interpret
					}
				}
			};
			{pm.loadPositions}.defer
		},
		showPresetDifference: {|name = "test"|
			var preset = Object.readArchive(pm.presetPath +/+ name ++ ".preset");
			preset.keysValuesDo {|str, ev|
				ev.pairsDo {|k, v|
					var currentVal = (str ++ "['" ++ k ++ "']").interpret;
					if(currentVal != v){
						(str ++ "." ++ k).postln;
						("" ++ currentVal ++ " --> " ++ v).postln;
					}
				}
			}
		},
		sendPresetsToOSC: {
			var presetsJSON = Dictionary.new();
			presetsJSON[\values] = Dictionary.new();
			pm.existingPresets.do {|sym|
				presetsJSON[\values][sym] = sym
			};
			~localHost.sendMsg("/EDIT", pmName +/+ "loadPreset", JSON.stringify(presetsJSON))
		},
		// gui stuff
		windows: (
			scopeGUI: ~scopeGUI.win,
			melodie: ~circles.guiElements.melodieWindow,
			melodie2: ~circles.guiElements.melodie2Window,
			bass: ~circles.guiElements.bassWindow,
			fft: ~gameFFT.pointerToWindow,
			bitflip: ~gameBitFlip.pointerToWindow,
			rhy1: ~game1.win,
			rhy2: ~game2.win,
			spectogramBig: ~spectograms.big.win,
			spectogramSmall: ~spectograms.small.win,
		),
		getPositions: {|self|
			self.positions = self.windows.collect { |w| w.bounds.origin }
		},
		loadPositions: {|self|
			self.windows.keysValuesDo {|k, win|
				win.bounds = Rect(self.positions[k].x, self.positions[k].y, win.bounds.width, win.bounds.height)
			};
		}
	);
	pm.getPositions;

	OSCdef((pmName ++ "loadPreset").asSymbol, {|msg|
		{pm[\loadPreset].(msg[1])}.defer;
	}, "/" ++ pmName +/+ "loadPreset").fix;

	OSCdef((pmName ++ "updatePreset").asSymbol, {|msg|
		("updating " ++ msg[1]).postln;
		{pm[\savePreset].(msg[1])}.defer;
	}, "/" ++ pmName +/+ "updatePreset").fix;

	pm.sendPresetsToOSC;
	pm
};
