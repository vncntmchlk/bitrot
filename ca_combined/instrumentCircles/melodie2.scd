// clicks
~circles.circleArray[5] = ~circles[\makeAngle].(radius: 60, circleNum: 5, waitDur: 8, guiColor: Color.hsv(0.55,1,1), circleParent: \melodie2);
~circles.circleArray[6] = ~circles[\makeAngle].(radius: 120, circleNum: 6, waitDur: 8, guiColor: Color.hsv(0.174,1,1), circleParent: \melodie2);

~circles.melodie2Circle = (
	circs: ~circles.circleArray[5..6],
	sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "melodie2"),
	points: [],
	instrumentName: "/notes1",
	instrumentChan: 1,
	taktLen: 16,
	guiText: "MELODIE2",
	presetManager: ~makePresetManager.("melodie2",[
		"~circles.melodie2Circle.sharedValues",
		"~circles.circleArray[5].sharedValues",
		"~circles.circleArray[6].sharedValues"
	]),
	lastTime: SystemClock.seconds
);

~circles.circleArray[5..6].do {|ev|
	var minTimeInBetween = 0.05; // 20 hz
	ev.sendIndexFunc = { |self, index|
		if(~circles.melodie2Circle.sharedValues.onOff.asBoolean){
			var now = SystemClock.seconds;
			if((now - ~circles.melodie2Circle.lastTime) > minTimeInBetween){
				~toPhilipp.sendMsg("/melody2Index", index, self.waitRateNow * thisThread.clock.tempo.reciprocal);
				~circles.melodie2Circle.lastTime = now
			}
		}
	}
};

OSCdef(\philippMelodie2, {|msg|
	// msg.postln;
	if(msg[1..].size == 16){
		~circles.melodie2Circle.noteArray = msg[1..];
	}
}, "/melody2List").fix;
~circles.melodie2Circle.noteArray = (56..71);
~circles.melodie2Circle.blockedIndices = Set.new();

~circles.melodie2Circle.drawNoteOn = { |index, color|
	{
		~circles.guiElements.melodie2NoteHits.add(index);
		~circles.guiElements.melodie2NoteHitColor[index] = color;
		~circles.guiElements.melodie2NotesView.refresh
	}.fork(AppClock);
};

~circles.melodie2Circle.drawNoteOff = { |index|
	{
		~circles.guiElements.melodie2NoteHits.remove(index);
		~circles.guiElements.melodie2NotesView.refresh
	}.fork(AppClock);
};

// variante 2 mit note drawing
~circles.melodie2Circle.monoNoteFunc = {
	~circles.circleArray[5..6].do {|ev|
		ev.noteFunc = { |self, vel, index|
			if(~circles.melodie2Circle.sharedValues.onOff.asBoolean){
				if(~circles.melodie2Circle.lastNote != ~circles.melodie2Circle.noteArray[index]){
					if(~circles.melodie2Circle.lastNote.notNil){
						//~mOut.noteOff(0, ~circles.melodie2Circle.lastNote);
						~toBenni.sendMsg(~circles.melodie2Circle.instrumentName, ~circles.melodie2Circle.lastNote, 0);
						~circles.melodie2Circle[\drawNoteOff].(~circles.melodie2Circle.lastIndex);
					};
					~circles.melodie2Circle[\drawNoteOn].(index, ev.guiColor.copy.alpha_(0.3));
					//~mOut.noteOn(0, ~melodie[index], 70);
					~toBenni.sendMsg(~circles.melodie2Circle.instrumentName, ~circles.melodie2Circle.noteArray[index], vel);
					~circles.melodie2Circle.lastNote = ~circles.melodie2Circle.noteArray[index];
					~circles.melodie2Circle.lastIndex = index;
					if(~circles.melodie2Circle.sharedValues.linkToRhy1Mute.asBoolean){
						Pdefn(\rhy1Mute).asStream.next
					};
					if(~circles.melodie2Circle.sharedValues.linkToClipSeq.asBoolean){
						Pdefn(\clipSequencer).asStream.next
					};
				}
			}
		}
	};
};
~circles.melodie2Circle.noteFunc = {
	~circles.circleArray[5..6].do {|ev, circleIndex|
		ev.noteFunc = { |self, vel, index|
			if(~circles.melodie2Circle.sharedValues.onOff.asBoolean){
				var offsetMidinote = [-12, 0, 12][circleIndex];
				~circles.melodie2Circle[\drawNoteOn].(index, ev.guiColor.copy.alpha_(0.3));
				if(~circles.melodie2Circle.sharedValues.linkToRhy1Mute.asBoolean){
					Pdefn(\rhy1Mute).asStream.next
				};
				if(~circles.melodie2Circle.sharedValues.linkToClipSeq.asBoolean){
					Pdefn(\clipSequencer).asStream.next
				};
				(
					midinote: ~circles.melodie2Circle.noteArray[index] + offsetMidinote,
					dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
					legato: self.sharedValues.circleLegato,
					type: \oscMidiNoteOffFunc,
					chan: ~circles.melodie2Circle.instrumentChan,
					netAddr: ~toBenni,
					noteOffFunc: {~circles.melodie2Circle[\drawNoteOff].(index)}
				).play
			}
		}
	};
};


~circles.melodie2Circle.monoNoteFunc.();
~circles.melodie2Circle.sharedValues.monoMode = 1;
~circles.melodie2Circle.sharedValues.onOff = 0;
~circles.melodie2Circle.sharedValues.noteArrayLen = 16;
~circles.melodie2Circle.sharedValues.linkToRhy1Mute = 0;
~circles.melodie2Circle.sharedValues.linkToClipSeq = 0;
~circles.melodie2Circle.sharedValues.freezeMe = true;
~circles.melodie2Circle.sharedValues.makeOSCdefsForKeys((
	monoMode: { |val|
		if(val.asBoolean){
			~circles.melodie2Circle.monoNoteFunc.();
		}{
			~circles.melodie2Circle.noteFunc.();
			if(~circles.melodie2Circle.lastNote.notNil){
				~toBenni.sendMsg(~circles.melodie2Circle.instrumentName, ~circles.melodie2Circle.lastNote, 0);
				~circles.melodie2Circle[\drawNoteOff].(~circles.melodie2Circle.lastIndex);
				~circles.melodie2Circle.lastNote = nil;
			};
		}
	},
	onOff: {|val|
		if(val.asBoolean){
			~circles.guiElements.melodie2RefreshPoints.start;
			{~circles.guiElements.melodie2Window.visible_(true)}.defer
		}{
			~circles.guiElements.melodie2RefreshPoints.stop;
			if(~circles.melodie2Circle.lastNote.notNil){
				~toBenni.sendMsg(~circles.melodie2Circle.instrumentName, ~circles.melodie2Circle.lastNote, 0);
				~circles.melodie2Circle[\drawNoteOff].(~circles.melodie2Circle.lastIndex);
				~circles.melodie2Circle.lastNote = nil;
			};
			{~circles.guiElements.melodie2Window.visible_(false)}.defer
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
~circles.melodie2Circle.sharedValues.sendAll;
