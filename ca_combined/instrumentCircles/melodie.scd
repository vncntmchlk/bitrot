~circles.circleArray[0] = ~circles[\makeAngle].(radius: 60, circleNum: 0, waitDur: 8, guiColor: Color.hsv(0,1,1), circleParent: \melodie);
~circles.circleArray[1] = ~circles[\makeAngle].(radius: 90, circleNum: 1, waitDur: 8, guiColor: Color.hsv(0.1,1,1), circleParent: \melodie);
~circles.circleArray[2] = ~circles[\makeAngle].(radius: 120, circleNum: 2, waitDur: 8, guiColor: Color.hsv(0.9,1,1), circleParent: \melodie);

~circles.melodieCircle = (
	circs: ~circles.circleArray[0..2],
	sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "melodie"),
	points: [],
	instrumentName: "notes0",
	instrumentChan: 0,
	taktLen: 16,
	guiText: "MELODIE",
	presetManager: ~makePresetManager.("melodie",[
		"~circles.melodieCircle.sharedValues",
		"~circles.circleArray[0].sharedValues",
		"~circles.circleArray[1].sharedValues",
		"~circles.circleArray[2].sharedValues"
	]),
	lastTime: SystemClock.seconds
);

~circles.melodieCircle.noteArray = (60..75).scramble;
OSCdef(\philippMelody, {|msg|
	// msg.postln;
	if(msg[1..].size == 16){
		~circles.melodieCircle.noteArray = msg[1..];
	}
}, "/melodyList").fix;

~circles.circleArray[0..2].do {|ev|
	var minTimeInBetween = 0.05; // 20 hz
	ev.sendIndexFunc = { |self, index|
		if(~circles.melodieCircle.sharedValues.onOff.asBoolean){
			var now = SystemClock.seconds;
			if((now - ~circles.melodieCircle.lastTime) > minTimeInBetween){
				~toPhilipp.sendMsg("/melodyIndex", index, self.waitRateNow * thisThread.clock.tempo.reciprocal);
				~circles.melodieCircle.lastTime = now
			}
		}
	}
};

~circles.melodieCircle.blockedIndices = Set.new();

~circles.melodieCircle.drawNoteOn = { |index, color|
	{
		~circles.guiElements.melodieNoteHits.add(index);
		~circles.guiElements.melodieNoteHitColor[index] = color;
		~circles.guiElements.melodieNotesView.refresh
	}.fork(AppClock);
};

~circles.melodieCircle.drawNoteOff = { |index|
	{
		~circles.guiElements.melodieNoteHits.remove(index);
		~circles.guiElements.melodieNotesView.refresh
	}.fork(AppClock);
};

// variante 2 mit note drawing
~circles.melodieCircle.monoNoteFunc = {
	~circles.circleArray[0..2].do {|ev|
		ev.noteFunc = { |self, vel, index|
			if(~circles.melodieCircle.sharedValues.onOff.asBoolean){
				if(~circles.melodieCircle.lastNote != ~circles.melodieCircle.noteArray[index]){
					if(~circles.melodieCircle.lastNote.notNil){
						//~mOut.noteOff(0, ~circles.melodieCircle.lastNote);
						~toBenni.sendMsg(~circles.melodieCircle.instrumentName, ~circles.melodieCircle.lastNote, 0);
						~circles.melodieCircle[\drawNoteOff].(~circles.melodieCircle.lastIndex);
					};
					~circles.melodieCircle[\drawNoteOn].(index, ev.guiColor.copy.alpha_(0.3));
					//~mOut.noteOn(0, ~melodie[index], 70);
					~toBenni.sendMsg(~circles.melodieCircle.instrumentName, ~circles.melodieCircle.noteArray[index], vel);
					~circles.melodieCircle.lastNote = ~circles.melodieCircle.noteArray[index];
					~circles.melodieCircle.lastIndex = index;
					if(~circles.melodieCircle.sharedValues.linkToRhy1Mute.asBoolean){
						Pdefn(\rhy1Mute).asStream.next
					};
					if(~circles.melodieCircle.sharedValues.linkToClipSeq.asBoolean){
						Pdefn(\clipSequencer).asStream.next
					};
				}
			}
		}
	};
};
~circles.melodieCircle.noteFunc = {
	~circles.circleArray[0..2].do {|ev, circleIndex|
		ev.noteFunc = { |self, vel, index|
			if(~circles.melodieCircle.sharedValues.onOff.asBoolean){
				var offsetMidinote = [-12, 0, 12][circleIndex];
				~circles.melodieCircle[\drawNoteOn].(index, ev.guiColor.copy.alpha_(0.3));
				if(~circles.melodieCircle.sharedValues.linkToRhy1Mute.asBoolean){
					Pdefn(\rhy1Mute).asStream.next
				};
				if(~circles.melodieCircle.sharedValues.linkToClipSeq.asBoolean){
					Pdefn(\clipSequencer).asStream.next
				};
				(
					midinote: ~circles.melodieCircle.noteArray[index] + offsetMidinote,
					dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
					legato: self.sharedValues.circleLegato,
					type: \oscMidiNoteOffFunc,
					chan: ~circles.melodieCircle.instrumentChan,
					netAddr: ~toBenni,
					noteOffFunc: {~circles.melodieCircle[\drawNoteOff].(index)}
				).play
			}
		}
	};
};

~circles.melodieCircle.monoNoteFunc.();

~circles.melodieCircle.sharedValues.freezeMe = true;
~circles.melodieCircle.sharedValues.monoMode = 1;
~circles.melodieCircle.sharedValues.linkToRhy1Mute = 0;
~circles.melodieCircle.sharedValues.linkToClipSeq = 0;
~circles.melodieCircle.sharedValues.onOff = 0;
~circles.melodieCircle.sharedValues.noteArrayLen = 16; // ist mit Quantisierung der noten verknuepft

~circles.melodieCircle.sharedValues.makeOSCdefsForKeys((
	monoMode: { |val|
		if(val.asBoolean){
			~circles.melodieCircle.monoNoteFunc.();
		}{
			~circles.melodieCircle.noteFunc.();
			if(~circles.melodieCircle.lastNote.notNil){
				~toBenni.sendMsg(~circles.melodieCircle.instrumentName, ~circles.melodieCircle.lastNote, 0);
				~circles.melodieCircle[\drawNoteOff].(~circles.melodieCircle.lastIndex);
				~circles.melodieCircle.lastNote = nil;
			};
		}
	},
	onOff: {|val|
		if(val.asBoolean){
			~circles.guiElements.melodieRefreshPoints.start;
			{~circles.guiElements.melodieWindow.visible_(true)}.defer
		}{
			~circles.guiElements.melodieRefreshPoints.stop;
			if(~circles.melodieCircle.lastNote.notNil){
				~toBenni.sendMsg(~circles.melodieCircle.instrumentName, ~circles.melodieCircle.lastNote, 0);
				~circles.melodieCircle[\drawNoteOff].(~circles.melodieCircle.lastIndex);
				~circles.melodieCircle.lastNote = nil;
			};
			{~circles.guiElements.melodieWindow.visible_(false)}.defer
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
~circles.melodieCircle.sharedValues.sendAll;
