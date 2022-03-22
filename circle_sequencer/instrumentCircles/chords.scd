// clicks
~circles.circleArray[3] = ~circles[\makeAngle].(radius: 60, circleNum: 3, waitDur: 8, guiColor: Color.hsv(0.8,1,1));
~circles.circleArray[4] = ~circles[\makeAngle].(radius: 90, circleNum: 4, waitDur: 8, guiColor: Color.hsv(0.7,1,1));
~circles.circleArray[5] = ~circles[\makeAngle].(radius: 120, circleNum: 5, waitDur: 8, guiColor: Color.hsv(0.6,1,1));
~circles.circleArray[3..5].do {|ev|
	ev.noteFunc = { |self, arr|
		//~toBenni.sendMsg("/circleNumber", self.circleNum, self.sharedValues.instrumentNum, vel);
		// ~mOut.noteOn(self.sharedValues.instrumentNum, self.circleNum.mod(3) + 36,vel)
		// [self.circleNum, self.sharedValues.instrumentNum, vel].postln
	}
};

~circles.chordsCircle = (
	circs: ~circles.circleArray[3..5],
	sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "chords"),
	points: [],
	instrumentName: "notes1",
	instrumentChan: 1,
	guiText: "CHORDS"
);

~circles.chordsCircle[3..5].do {|ev|
	ev.sendIndexFunc = { |self, schedCalc|
		var indexDur = self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 16 / 4;
		var index = self.testAngle.linlin(0, 359, 0, 15.999).round(1); // sollte besser sein?
		var retIndex = nil;
		[index, indexDur, schedCalc].postln;
		if(~circles.melodieCircle.blockedIndices.includes(index).not){
			~toPhilipp.sendMsg("/melodyIndex", index);
			retIndex = index;
		};
		~circles.melodieCircle.blockedIndices.add(index);
		thisThread.clock.sched(
			indexDur + 0.01,
			{~circles.melodieCircle.blockedIndices.remove(index); nil}
		);
		retIndex
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

// variante 2 mit note drawing
~circles.chordsCircle.monoNoteFunc = {
	~circles.circleArray[3..5].do {|ev|
		ev.noteFunc = { |self, vel, index|
			if(~circles.chordsCircle.lastNote != ~circles.chordsCircle.noteArray[index]){
				if(~circles.chordsCircle.lastNote.notNil){
					//~mOut.noteOff(0, ~circles.lastMelodieNote);
					~toBenni.sendMsg(~circles.chordsCircle.instrumentName, ~circles.chordsCircle.lastNote, 0);
				};
				~toBenni.sendMsg(~circles.chordsCircle.instrumentName, ~circles.chordsCircle.noteArray[index], vel);
				~circles.chordsCircle.lastNote = ~circles.chordsCircle.noteArray[index];
			}
		}
	};
};
~circles.chordsCircle.noteFunc = {
	~circles.circleArray[3..5].do {|ev|
		ev.noteFunc = { |self, vel, index|
			(
				midinote: ~circles.chordsCircle.noteArray[index],
				dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
				legato: self.sharedValues.circleLegato,
				type: \oscMidi,
				chan: ~circles.chordsCircle.instrumentChan,
				netAddr: ~toBenni
			).play
		}
	};
};

~circles.chordsCircle.noteFunc.();
~circles.chordsCircle.sharedValues.monoMode = 1;
~circles.chordsCircle.sharedValues.onOff = 0;
~circles.chordsCircle.sharedValues.freezeMe = true;
~circles.chordsCircle.sharedValues.makeOSCdefsForKeys((
	monoMode: { |val|
		if(val.asBoolean){
			~circles.chordsCircle.monoNoteFunc.();
		}{
			~circles.chordsCircle.noteFunc.();
		}
	},
	onOff: {|val|
		if(val.asBoolean){
			// ~circles.guiElements.refreshPointsBass.start;
			~circles.guiElements.chordsRefreshPoints.start;
			{~circles.guiElements.melodieWindow.visible_(true)}.defer
		}{
			// ~circles.guiElements.refreshPointsBass.stop;
			~circles.guiElements.chordsRefreshPoints.stop;
			{~circles.guiElements.melodieWindow.visible_(false)}.defer
		}
	}
));
~circles.chordsCircle.sharedValues.sendAll;
