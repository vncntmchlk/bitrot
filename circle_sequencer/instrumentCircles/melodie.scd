~circles.circleArray[0] = ~circles[\makeAngle].(radius: 60, circleNum: 0, waitDur: 8, guiColor: Color.hsv(0,1,1));
~circles.circleArray[1] = ~circles[\makeAngle].(radius: 90, circleNum: 1, waitDur: 8, guiColor: Color.hsv(0.1,1,1));
~circles.circleArray[2] = ~circles[\makeAngle].(radius: 120, circleNum: 2, waitDur: 8, guiColor: Color.hsv(0.9,1,1));

~circles.melodieCircle = (
	circs: ~circles.circleArray[0..2],
	sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "melodie"),
	points: [],
	instrumentName: "notes0",
	instrumentChan: 0,
	guiText: "MELODIE"
);

~circles.melodieCircle.noteArray = (60..75);
OSCdef(\philippMelody, {|msg|
	// msg.postln;
	if(msg[1..].size == 16){
		~circles.melodieCircle.noteArray = msg[1..];
	}
}, "/melodyList").fix;

~circles.circleArray[0..2].do {|ev|
	ev.sendIndexFunc = { |self, index|
		~toPhilipp.sendMsg("/melodyIndex", index);
	}
};

~circles.melodieCircle.blockedIndices = Set.new();

// variante 2 mit note drawing
~circles.melodieCircle.monoNoteFunc = {
	~circles.circleArray[0..2].do {|ev|
		ev.noteFunc = { |self, vel, index|
			if(~circles.melodieCircle.lastNote != ~circles.melodieCircle.noteArray[index]){
				if(~circles.melodieCircle.lastNote.notNil){
					//~mOut.noteOff(0, ~circles.melodieCircle.lastNote);
					~toBenni.sendMsg(~circles.melodieCircle.instrumentName, ~circles.melodieCircle.lastNote, 0);
				};
				~circles.guiElements.notesHits.add(index);
				{
					~circles.guiElements.noteHitColor = ev.guiColor.copy.alpha_(0.3);
					~circles.guiElements.notesView.refresh
				}.fork(AppClock);
				//~mOut.noteOn(0, ~melodie[index], 70);
				~toBenni.sendMsg(~circles.melodieCircle.instrumentName, ~circles.melodieCircle.noteArray[index], vel);
				~circles.melodieCircle.lastNote = ~circles.melodieCircle.noteArray[index];
				if(~circles.melodieCircle.sharedValues.linkToRhy1Mute.asBoolean){
					Pdefn(\rhy1Mute).asStream.next
				};
			};
		}
	};
};
~circles.melodieCircle.noteFunc = {
	~circles.circleArray[0..2].do {|ev, circleIndex|
		ev.noteFunc = { |self, vel, index|
			var offsetMidinote = [-12, 0, 12][circleIndex];
			{
				~circles.guiElements.notesHits.add(index);
				~circles.guiElements.noteHitColor = ev.guiColor.copy.alpha_(0.3);
				~circles.guiElements.notesView.refresh
			}.fork(AppClock);
			if(~circles.melodieCircle.sharedValues.linkToRhy1Mute.asBoolean){
				Pdefn(\rhy1Mute).asStream.next
			};
			(
				midinote: ~circles.melodieCircle.noteArray[index] + offsetMidinote,
				dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
				legato: self.sharedValues.circleLegato,
				type: \oscMidi,
				chan: ~circles.melodieCircle.instrumentChan,
				netAddr: ~toBenni
			).play
		}
	};
};

~circles.melodieCircle.monoNoteFunc.();

~circles.melodieCircle.sharedValues.freezeMe = true;
~circles.melodieCircle.sharedValues.monoMode = 1;
~circles.melodieCircle.sharedValues.linkToRhy1Mute = 0;
~circles.melodieCircle.sharedValues.onOff = 0;
~circles.melodieCircle.sharedValues.makeOSCdefsForKeys((
	monoMode: { |val|
		if(val.asBoolean){
			~circles.melodieCircle.monoNoteFunc.();
		}{
			~circles.melodieCircle.noteFunc.();
			if(~circles.melodieCircle.lastNote.notNil){
				~toBenni.sendMsg(~circles.melodieCircle.instrumentName, ~circles.melodieCircle.lastNote, 0);
				~circles.melodieCircle.lastNote = nil;
			};
		}
	},
	onOff: {|val|
		if(val.asBoolean){
			// ~circles.guiElements.refreshPointsMelodie.start;
			~circles.guiElements.melodieRefreshPoints.start;
			{~circles.guiElements.melodieWindow.visible_(true)}.defer
		}{
			// ~circles.guiElements.refreshPointsMelodie.stop;
			~circles.guiElements.melodieRefreshPoints.stop;
			if(~circles.melodieCircle.lastNote.notNil){
				~toBenni.sendMsg(~circles.melodieCircle.instrumentName, ~circles.melodieCircle.lastNote, 0);
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
	}
));
~circles.melodieCircle.sharedValues.sendAll;
