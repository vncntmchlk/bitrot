~presetPath = PathName(thisProcess.nowExecutingPath).pathOnly  ++ "presets";

~makePresetManager = { |pmName, evNames|
	var pm = (
		presetPath: ~presetPath +/+ pmName,
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
			/*var presetsJSON = (values: ());*/
			var presetsJSON = Dictionary.new();
			presetsJSON[\values] = Dictionary.new();
			pm.existingPresets.do {|sym|
				presetsJSON[\values][sym] = sym
			};
			~localHost.sendMsg("/EDIT", pmName +/+ "loadPreset", JSON.stringify(presetsJSON))
		},
		dropDownSelection: nil,
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


/*~presetManager = (
globalEvNames: (
melodie: [
"~circles.melodieCircle.sharedValues",
"~circles.circleArray[0].sharedValues",
"~circles.circleArray[1].sharedValues",
"~circles.circleArray[2].sharedValues"
],
bass: [
"~circles.bassCircle.sharedValues",
"~circles.circleArray[3].sharedValues",
"~circles.circleArray[4].sharedValues"
],
chords: [
"~circles.chordsCircle.sharedValues",
"~circles.circleArray[5].sharedValues",
"~circles.circleArray[6].sharedValues"
],
rhy: [
"~game1.sharedEv",
"~game2.sharedEv"
],
fft: [
"~gameFFT.sharedEv"
],
bitflip: [
"~gameBitFlip.sharedEv"
],
all: [
"~circles.melodieCircle.sharedValues",
"~circles.circleArray[0].sharedValues",
"~circles.circleArray[1].sharedValues",
"~circles.circleArray[2].sharedValues",
"~circles.bassCircle.sharedValues",
"~circles.circleArray[3].sharedValues",
"~circles.circleArray[4].sharedValues",
"~circles.chordsCircle.sharedValues",
"~circles.circleArray[5].sharedValues",
"~circles.circleArray[6].sharedValues",
"~game1.sharedEv",
"~game2.sharedEv",
"~gameFFT.sharedEv",
"~gameBitFlip.sharedEv"
]
),
presetPath: PathName(thisProcess.nowExecutingPath).pathOnly ++ "presets",
existingPresets: {
PathName(~presetManager.presetPath).files.collect {|file| file.fileNameWithoutExtension}
},
savePreset: {|saveThese = ([]), name = "test"|
var preset = ();
var strArray = [];
saveThese.do {|sym| strArray = strArray ++ ~presetManager.globalEvNames[sym]};
strArray.do { |str|
preset[str.asSymbol] = str.interpret.as(Dictionary); // vom OSCSharedEvent umwandeln
};
preset.writeArchive(~presetManager.presetPath +/+ name ++ ".preset");
{~presetManager.sendPresetsToOSC}.defer(0.5); // dropdown aktualisieren
},
/*savePreset: {|saveThese = ([]), name = "test"|
var preset = ();
saveThese.do { |str|
preset[str.asSymbol] = str.interpret.as(Dictionary); // vom OSCSharedEvent umwandeln
};
preset.writeArchive(~presetManager.presetPath +/+ name ++ ".preset");
},*/
/*loadPreset: {|name = "test"|
var preset = Object.readArchive(~presetManager.presetPath +/+ name ++ ".preset");
preset.keysValuesDo {|str, ev|
ev.pairsDo {|k, v|
(str ++ "['" ++ k ++ "'] = " ++ v).interpret
}
}
},*/
// nur die geaenderten laden
loadPreset: {|name = "test"|
var preset = Object.readArchive(~presetManager.presetPath +/+ name ++ ".preset");
preset.keysValuesDo {|str, ev|
ev.pairsDo {|k, v|
var currentVal = (str ++ "['" ++ k ++ "']").interpret;
if(currentVal != v){
(str ++ "['" ++ k ++ "'] = " ++ v).interpret
// (str ++ "." ++ k).postln;
// ("" ++ currentVal ++ " --> " ++ v).postln;
}
}
}
},
showPresetDifference: {|name = "test"|
var preset = Object.readArchive(~presetManager.presetPath +/+ name ++ ".preset");
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
var presetsJSON = (values: ());
~presetManager.existingPresets.do {|sym|
presetsJSON[\values][sym] = sym
};
~localHost.sendMsg("/EDIT", "presetSelection", JSON.stringify(presetsJSON))
},
dropDownSelection: nil,
);

OSCdef(\loadThePreset, {|msg|
~presetManager[\loadPreset].(msg[1]);
~presetManager.dropDownSelection = msg[1];
}, "/presetSelection").fix;

OSCdef(\updateThePreset, {|msg|
("updating " ++ msg[1]).postln;
~presetManager.dropDownSelection = msg[1];
}, "/updatePreset").fix;*/
