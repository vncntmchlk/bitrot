~presetManager = (
	presetPath: PathName(thisProcess.nowExecutingPath).pathOnly ++ "presets",
	savePreset: {|saveThese = ([]), name = "test"|
		var preset = ();
		saveThese.do { |str|
			preset[str.asSymbol] = str.interpret.as(Dictionary); // vom OSCSharedEvent umwandeln
		};
		preset.writeArchive(~presetManager.presetPath +/+ name ++ ".preset");
	},
	loadPreset: {|name = "test"|
		var preset = Object.readArchive(~presetManager.presetPath +/+ name ++ ".preset");
		preset.keysValuesDo {|str, ev|
			ev.pairsDo {|k, v|
				(str ++ "['" ++ k ++ "'] = " ++ v).interpret
			}
		}
	}
);

