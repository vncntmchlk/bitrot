// clicks
~circles.circleArray[3] = ~circles[\makeAngle].(radius: 60, circleNum: 3, waitDur: 8, guiColor: Color.hsv(0.8,1,1), circleParent: \bass);
~circles.circleArray[4] = ~circles[\makeAngle].(radius: 120, circleNum: 4, waitDur: 8, guiColor: Color.hsv(0.7,1,1), circleParent: \bass);

~circles.bassCircle = (
	circs: ~circles.circleArray[3..4],
	sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "bass"),
	points: [],
	instrumentName: "notes2",
	instrumentChan: 2,
	taktLen: 16,
	guiText: "BASS",
	presetManager: ~makePresetManager.("bass",[
		"~circles.bassCircle.sharedValues",
		"~circles.circleArray[3].sharedValues",
		"~circles.circleArray[4].sharedValues"
	])
);

~circles.bassCircle[3..4].do {|ev|
	ev.sendIndexFunc = { |self, index|
		~toPhilipp.sendMsg("/bassIndex", index);
	}
};

// ~bassLine =
OSCdef(\philippBassLine, {|msg|
	// msg.postln;
	if(msg[1..].size == 16){
		~circles.bassCircle.noteArray = msg[1..];
	}
}, "/bassList").fix;
~circles.bassCircle.noteArray = (36..51);
~circles.bassCircle.blockedIndices = Set.new();

~circles.bassCircle.drawNoteOn = { |index, color|
	{
		~circles.guiElements.bassNoteHits.add(index);
		~circles.guiElements.bassNoteHitColor[index] = color;
		~circles.guiElements.bassNotesView.refresh
	}.fork(AppClock);
};

~circles.bassCircle.drawNoteOff = { |index|
	{
		~circles.guiElements.bassNoteHits.remove(index);
		~circles.guiElements.bassNotesView.refresh
	}.fork(AppClock);
};

// variante 2 mit note drawing
~circles.bassCircle.monoNoteFunc = {
	~circles.circleArray[3..4].do {|ev|
		ev.noteFunc = { |self, vel, index|
			if(~circles.bassCircle.sharedValues.onOff.asBoolean){
				if(~circles.bassCircle.lastNote != ~circles.bassCircle.noteArray[index]){
					if(~circles.bassCircle.lastNote.notNil){
						//~mOut.noteOff(0, ~circles.bassCircle.lastNote);
						~toBenni.sendMsg(~circles.bassCircle.instrumentName, ~circles.bassCircle.lastNote, 0);
						~circles.bassCircle[\drawNoteOff].(~circles.bassCircle.lastIndex);
					};
					~circles.bassCircle[\drawNoteOn].(index, ev.guiColor.copy.alpha_(0.3));
					//~mOut.noteOn(0, ~melodie[index], 70);
					~toBenni.sendMsg(~circles.bassCircle.instrumentName, ~circles.bassCircle.noteArray[index], vel);
					~circles.bassCircle.lastNote = ~circles.bassCircle.noteArray[index];
					~circles.bassCircle.lastIndex = index;
					if(~circles.bassCircle.sharedValues.linkToRhy1Mute.asBoolean){
						Pdefn(\rhy1Mute).asStream.next
					};
					if(~circles.bassCircle.sharedValues.linkToClipSeq.asBoolean){
						Pdefn(\clipSequencer).asStream.next
					};
				}
			}
		}
	};
};
~circles.bassCircle.noteFunc = {
	~circles.circleArray[3..4].do {|ev|
		ev.noteFunc = { |self, vel, index|
			if(~circles.bassCircle.sharedValues.onOff.asBoolean){
				~circles.bassCircle[\drawNoteOn].(index, ev.guiColor.copy.alpha_(0.3));
				if(~circles.bassCircle.sharedValues.linkToRhy1Mute.asBoolean){
					Pdefn(\rhy1Mute).asStream.next
				};
				if(~circles.bassCircle.sharedValues.linkToClipSeq.asBoolean){
					Pdefn(\clipSequencer).asStream.next
				};
				(
					midinote: ~circles.bassCircle.noteArray[index],
					dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
					legato: self.sharedValues.circleLegato,
					type: \oscMidiNoteOffFunc,
					chan: ~circles.bassCircle.instrumentChan,
					netAddr: ~toBenni,
					noteOffFunc: {~circles.bassCircle[\drawNoteOff].(index)}
				).play
			}
		}
	};
};

~circles.bassCircle.noteFunc.();
~circles.bassCircle.sharedValues.monoMode = 1;
~circles.bassCircle.sharedValues.onOff = 0;
~circles.bassCircle.sharedValues.noteArrayLen = 16;
~circles.bassCircle.sharedValues.linkToRhy1Mute = 0;
~circles.bassCircle.sharedValues.linkToClipSeq = 0;
~circles.bassCircle.sharedValues.freezeMe = true;
~circles.bassCircle.sharedValues.makeOSCdefsForKeys((
	monoMode: { |val|
		if(val.asBoolean){
			~circles.bassCircle.monoNoteFunc.();
		}{
			~circles.bassCircle.noteFunc.();
			if(~circles.bassCircle.lastNote.notNil){
				~toBenni.sendMsg(~circles.bassCircle.instrumentName, ~circles.bassCircle.lastNote, 0);
				~circles.bassCircle[\drawNoteOff].(~circles.bassCircle.lastIndex);
				~circles.bassCircle.lastNote = nil;
			};
		}
	},
	onOff: {|val|
		if(val.asBoolean){
			~circles.guiElements.bassRefreshPoints.start;
			{~circles.guiElements.bassWindow.visible_(true)}.defer
		}{
			~circles.guiElements.bassRefreshPoints.stop;
			if(~circles.bassCircle.lastNote.notNil){
				~toBenni.sendMsg(~circles.bassCircle.instrumentName, ~circles.bassCircle.lastNote, 0);
				~circles.bassCircle[\drawNoteOff].(~circles.bassCircle.lastIndex);
				~circles.bassCircle.lastNote = nil;
			};
			{~circles.guiElements.bassWindow.visible_(false)}.defer
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
~circles.bassCircle.sharedValues.sendAll;
