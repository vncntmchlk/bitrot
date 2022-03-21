// clicks
~circles.circleArray[3] = ~circles[\makeAngle].(radius: 60, circleNum: 3, waitDur: 8, quantVal: 8, guiColor: Color.hsv(0.8,1,1));
~circles.circleArray[4] = ~circles[\makeAngle].(radius: 90, circleNum: 4, waitDur: 8, quantVal: 8, guiColor: Color.hsv(0.7,1,1));
~circles.circleArray[5] = ~circles[\makeAngle].(radius: 120, circleNum: 5, waitDur: 8, quantVal: 8, guiColor: Color.hsv(0.6,1,1));
~circles.circleArray[3..5].do {|ev|
	ev.noteFunc = { |self, arr|
		//~toBenni.sendMsg("/circleNumber", self.circleNum, self.sharedValues.instrumentNum, vel);
		// ~mOut.noteOn(self.sharedValues.instrumentNum, self.circleNum.mod(3) + 36,vel)
		// [self.circleNum, self.sharedValues.instrumentNum, vel].postln
	}
};

~circles.bassCircle = (
	circs: ~circles.circleArray[3..5],
	sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "bass"),
	points: [],
	instrumentName: "notes2",
	instrumentChan: 2,
	guiText: "BASS"
);

~circles.bassCircle[3..5].do {|ev|
	ev.sendIndexFunc = { |self, vel|
		var totalTaktDur = self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel;
		var taktStufe = thisThread.beats.mod(totalTaktDur / 4);
		var index = ((
			(taktStufe / (totalTaktDur)) * 4
		) * 15.999);//.asInteger;//.round.clip(0,15);
		if(totalTaktDur < 16){
			index = index.asInteger
		}{
			index = index.round.clip(0,15);
		};
		if(~circles.bassCircle.blockedIndices.includes(index).not){
			~toPhilipp.sendMsg("/bassIndex", index);
			thisThread.clock.sched(self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 16 - self.lookAheadTime, {
				ev.noteFunc(vel, index);
				nil
			})
		};
		~circles.bassCircle.blockedIndices.add(index);
		thisThread.clock.sched(self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 16, {
			~circles.bassCircle.blockedIndices.remove(index); nil
		});
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

// variante 2 mit note drawing
~circles.bassCircle.monoNoteFunc = {
	~circles.circleArray[3..5].do {|ev|
		ev.noteFunc = { |self, vel, index|
			/*var totalTaktDur = self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel;
			var taktStufe = thisThread.beats.mod(totalTaktDur / 4);
			var index = ((taktStufe / (totalTaktDur)) * 4) * 15.999;//.asInteger;//.round.clip(0,15);
			if(totalTaktDur < 16){
			index = index.asInteger
			}{
			index = index.round.clip(0,15);
			};*/
			//if(~circles.chordsBassCircle.blockedIndices.includes(index).not){
			//~toPhilipp.sendMsg("/bassIndex", index.postln);
			if(~circles.bassCircle.lastNote != ~circles.bassCircle.noteArray[index]){
				if(~circles.bassCircle.lastNote.notNil){
					//~mOut.noteOff(0, ~circles.lastMelodieNote);
					~toBenni.sendMsg(~circles.bassCircle.instrumentName, ~circles.bassCircle.lastNote, 0);
				};
				//~circles.guiElements.notesHits.add(index);
				/*{
				~circles.guiElements.noteHitColor = ev.guiColor.copy.alpha_(0.3);
				~circles.guiElements.notesView.refresh
				}.fork(AppClock);*/
				//~mOut.noteOn(0, ~melodie[index], 70);
				~toBenni.sendMsg(~circles.bassCircle.instrumentName, ~circles.bassCircle.noteArray[index], vel);
				~circles.bassCircle.lastNote = ~circles.bassCircle.noteArray[index];
			}
			//};
			/*~circles.chordsBassCircle.blockedIndices.add(index);
			thisThread.clock.sched(self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 16, {
			~circles.chordsBassCircle.blockedIndices.remove(index); nil
			});*/
		}
	};
};
~circles.bassCircle.noteFunc = {
	~circles.circleArray[3..5].do {|ev|
		ev.noteFunc = { |self, vel, index|
			/*var totalTaktDur = self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel;
			var taktStufe = thisThread.beats.mod(totalTaktDur / 4);
			var index = ((taktStufe / (totalTaktDur)) * 4) * 15.999;//.asInteger;//.round.clip(0,15);
			if(totalTaktDur < 16){
			index = index.asInteger
			}{
			index = index.round.clip(0,15);
			};
			if(~circles.chordsBassCircle.blockedIndices.includes(index).not){*/

			/*{
			~circles.guiElements.notesHits.add(index);
			~circles.guiElements.noteHitColor = ev.guiColor.copy.alpha_(0.3);
			~circles.guiElements.notesView.refresh
			}.fork(AppClock);*/
			//~toPhilipp.sendMsg("/bassIndex", index);
			(
				midinote: ~circles.bassCircle.noteArray[index],
				dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
				legato: self.sharedValues.circleLegato,
				type: \oscMidi,
				chan: ~circles.bassCircle.instrumentChan,
				netAddr: ~toBenni
			).play
			//};
			/*~circles.chordsBassCircle.blockedIndices.add(index);
			thisThread.clock.sched(self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 16, {
			~circles.chordsBassCircle.blockedIndices.remove(index); nil
			});*/
		}
	};
};

~circles.bassCircle.noteFunc.();
~circles.bassCircle.sharedValues.monoMode = 1;
~circles.bassCircle.sharedValues.onOff = 0;
~circles.bassCircle.sharedValues.freezeMe = true;
~circles.bassCircle.sharedValues.makeOSCdefsForKeys((
	monoMode: { |val|
		if(val.asBoolean){
			~circles.bassCircle.monoNoteFunc.();
		}{
			~circles.bassCircle.noteFunc.();
		}
	},
	onOff: {|val|
		if(val.asBoolean){
			// ~circles.guiElements.refreshPointsBass.start;
			~circles.guiElements.bassRefreshPoints.start;
			{~circles.guiElements.melodieWindow.visible_(true)}.defer
		}{
			// ~circles.guiElements.refreshPointsBass.stop;
			~circles.guiElements.bassRefreshPoints.stop;
			{~circles.guiElements.melodieWindow.visible_(false)}.defer
		}
	}
));
~circles.bassCircle.sharedValues.sendAll;
