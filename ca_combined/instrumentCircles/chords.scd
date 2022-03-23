// clicks
~circles.circleArray[5] = ~circles[\makeAngle].(radius: 60, circleNum: 5, waitDur: 8, guiColor: Color.hsv(0.55,1,1), circleParent: \chords);
~circles.circleArray[6] = ~circles[\makeAngle].(radius: 120, circleNum: 6, waitDur: 8, guiColor: Color.hsv(0.174,1,1), circleParent: \chords);

~circles.chordsCircle = (
	circs: ~circles.circleArray[5..6],
	sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "chords"),
	points: [],
	instrumentName: "notes1",
	instrumentChan: 1,
	taktLen: 16,
	guiText: "CHORDS",
	presetManager: ~makePresetManager.("chords",[
		"~circles.chordsCircle.sharedValues",
		"~circles.circleArray[5].sharedValues",
		"~circles.circleArray[6].sharedValues"
	])
);

~circles.chordsCircle[5..6].do {|ev|
	ev.sendIndexFunc = { |self, index|
		~toPhilipp.sendMsg("/chordsIndex", index);
	}
};

OSCdef(\philippChords, {|msg|
	// msg.postln;
	if(msg[1..].size == 16){
		~circles.chordsCircle.noteArray = msg[1..];
	}
}, "/chordsList").fix;
~circles.chordsCircle.noteArray = (36..51);
~circles.chordsCircle.blockedIndices = Set.new();

~circles.chordsCircle.drawNoteOn = { |index, color|
	{
		~circles.guiElements.chordsNoteHits.add(index);
		~circles.guiElements.chordsNoteHitColor[index] = color;
		~circles.guiElements.chordsNotesView.refresh
	}.fork(AppClock);
};

~circles.chordsCircle.drawNoteOff = { |index|
	{
		~circles.guiElements.chordsNoteHits.remove(index);
		~circles.guiElements.chordsNotesView.refresh
	}.fork(AppClock);
};

~circles.chordsCircle.monoNoteFunc = {
	~circles.circleArray[5..6].do {|ev|
		ev.noteFunc = { |self, vel, index|
			if(~circles.chordsCircle.sharedValues.onOff.asBoolean){
				if(~circles.chordsCircle.lastNote != ~circles.chordsCircle.noteArray[index]){
					if(~circles.chordsCircle.lastNote.notNil){
						//~mOut.noteOff(0, ~circles.chordsCircle.lastNote);
						~toBenni.sendMsg(~circles.chordsCircle.instrumentName, ~circles.chordsCircle.lastNote, 0);
						~circles.chordsCircle[\drawNoteOff].(~circles.chordsCircle.lastIndex);
					};
					~circles.chordsCircle[\drawNoteOn].(index, ev.guiColor.copy.alpha_(0.3));
					//~mOut.noteOn(0, ~melodie[index], 70);
					~toBenni.sendMsg(~circles.chordsCircle.instrumentName, ~circles.chordsCircle.noteArray[index], vel);
					~circles.chordsCircle.lastNote = ~circles.chordsCircle.noteArray[index];
					~circles.chordsCircle.lastIndex = index;
					if(~circles.chordsCircle.sharedValues.linkToRhy1Mute.asBoolean){
						Pdefn(\rhy1Mute).asStream.next
					};
					if(~circles.chordsCircle.sharedValues.linkToClipSeq.asBoolean){
						Pdefn(\clipSequencer).asStream.next
					};
				}
			}
		}
	};
};
~circles.chordsCircle.noteFunc = {
	~circles.circleArray[5..6].do {|ev|
		ev.noteFunc = { |self, vel, index|
			if(~circles.chordsCircle.sharedValues.onOff.asBoolean){
				~circles.chordsCircle[\drawNoteOn].(index, ev.guiColor.copy.alpha_(0.3));
				if(~circles.chordsCircle.sharedValues.linkToRhy1Mute.asBoolean){
					Pdefn(\rhy1Mute).asStream.next
				};
				if(~circles.chordsCircle.sharedValues.linkToClipSeq.asBoolean){
					Pdefn(\clipSequencer).asStream.next
				};
				(
					midinote: ~circles.chordsCircle.noteArray[index],
					dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
					legato: self.sharedValues.circleLegato,
					type: \oscMidiNoteOffFunc,
					chan: ~circles.chordsCircle.instrumentChan,
					netAddr: ~toBenni,
					drawOff: Pfunc {|ev|
						{
							~circles.chordsCircle[\drawNoteOff].(index)
						}.defer(ev.delta);
						0
					}
				).play
			}
		}
	};
};


~circles.chordsCircle.noteFunc.();
~circles.chordsCircle.sharedValues.monoMode = 1;
~circles.chordsCircle.sharedValues.onOff = 0;
~circles.chordsCircle.sharedValues.noteArrayLen = 16;
~circles.chordsCircle.sharedValues.linkToRhy1Mute = 0;
~circles.chordsCircle.sharedValues.linkToClipSeq = 0;
~circles.chordsCircle.sharedValues.freezeMe = true;
~circles.chordsCircle.sharedValues.makeOSCdefsForKeys((
	monoMode: { |val|
		if(val.asBoolean){
			~circles.chordsCircle.monoNoteFunc.();
		}{
			~circles.chordsCircle.noteFunc.();
			if(~circles.chordsCircle.lastNote.notNil){
				~toBenni.sendMsg(~circles.chordsCircle.instrumentName, ~circles.chordsCircle.lastNote, 0);
				~circles.chordsCircle[\drawNoteOff].(~circles.chordsCircle.lastIndex);
				~circles.chordsCircle.lastNote = nil;
			};
		}
	},
	onOff: {|val|
		if(val.asBoolean){
			~circles.guiElements.chordsRefreshPoints.start;
			{~circles.guiElements.chordsWindow.visible_(true)}.defer
		}{
			~circles.guiElements.chordsRefreshPoints.stop;
			if(~circles.chordsCircle.lastNote.notNil){
				~toBenni.sendMsg(~circles.chordsCircle.instrumentName, ~circles.chordsCircle.lastNote, 0);
				~circles.chordsCircle[\drawNoteOff].(~circles.chordsCircle.lastIndex);
				~circles.chordsCircle.lastNote = nil;
			};
			{~circles.guiElements.chordsWindow.visible_(false)}.defer
		}
	},
	linkToRhy1Mute: {|val|
		// sicherstellen dass unmuted ist wenn link ausgeschaltet wird
		if(val.asBoolean.not and: {~game1.externalMute}){
			Pdefn(\rhy1Mute).asStream.next
		}
	},
	linkToClipSeq: {|val|
		// turn off clips for sure
		if(val.asBoolean.not){
			~toBenni.sendMsg("/clips", 0);
		}
	}
));
~circles.chordsCircle.sharedValues.sendAll;
