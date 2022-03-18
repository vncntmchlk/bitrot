// clicks
~circles.circleArray[3] = ~circles[\makeAngle].(radius: 60, circleNum: 3, instrumentNum: 0, waitDur: 8, quantVal: 10, guiColor: Color.hsv(0.8,1,1));
~circles.circleArray[4] = ~circles[\makeAngle].(radius: 90, circleNum: 4, instrumentNum: 0, waitDur: 8, quantVal: 10, guiColor: Color.hsv(0.7,1,1));
~circles.circleArray[5] = ~circles[\makeAngle].(radius: 120, circleNum: 5, instrumentNum: 0, waitDur: 8, quantVal: 10, guiColor: Color.hsv(0.6,1,1));
~circles.circleArray[3..5].do {|ev|
	ev.noteFunc = { |self, arr|
		//~toBenni.sendMsg("/circleNumber", self.circleNum, self.sharedValues.instrumentNum, vel);
		// ~mOut.noteOn(self.sharedValues.instrumentNum, self.circleNum.mod(3) + 36,vel)
		// [self.circleNum, self.sharedValues.instrumentNum, vel].postln
	}
};

~circles.chordsBassCircle = (
	circs: ~circles.circleArray[3..5],
	sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "chordsBass"),
	points: [],
	guiText: "CHORDS BASS"
);

~bassLine = (36..51);

~circles.chordsBassCircle.blockedIndices = Set.new();

// variante 2 mit note drawing
~circles.chordsBassCircle.monoNoteFunc = {
	~circles.circleArray[3..5].do {|ev|
		ev.noteFunc = { |self, vel|
			var totalTaktDur = self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel;
			var taktStufe = thisThread.beats.mod(totalTaktDur / 4);
			var index = ((taktStufe / (totalTaktDur)) * 4) * 15.999;//.asInteger;//.round.clip(0,15);
			if(totalTaktDur < 16){
				index = index.asInteger
			}{
				index = index.round.clip(0,15);
			};
			if(~circles.chordsBassCircle.blockedIndices.includes(index).not){
				~toPhilipp.sendMsg("/bassIndex", index.postln);
				if(~circles.lastBassNote != ~bassLine[index]){
					if(~circles.lastBassNote.notNil){
						//~mOut.noteOff(0, ~circles.lastMelodieNote);
						~toBenni.sendMsg("notes2", ~circles.lastBassNote, 0);
					};
					//~circles.guiElements.notesHits.add(index);
					/*{
					~circles.guiElements.noteHitColor = ev.guiColor.copy.alpha_(0.3);
					~circles.guiElements.notesView.refresh
					}.fork(AppClock);*/
					//~mOut.noteOn(0, ~melodie[index], 70);
					~toBenni.sendMsg("notes2", ~bassLine[index], vel);
					~circles.lastBassNote = ~bassLine[index];
				}
			};
			~circles.chordsBassCircle.blockedIndices.add(index);
			thisThread.clock.sched(self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 16, {
				~circles.chordsBassCircle.blockedIndices.remove(index); nil
			});
		}
	};
};
~circles.chordsBassCircle.noteFunc = {
	~circles.circleArray[3..5].do {|ev|
		ev.noteFunc = { |self, vel|
			var totalTaktDur = self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel;
			var taktStufe = thisThread.beats.mod(totalTaktDur / 4);
			var index = ((taktStufe / (totalTaktDur)) * 4) * 15.999;//.asInteger;//.round.clip(0,15);
			if(totalTaktDur < 16){
				index = index.asInteger
			}{
				index = index.round.clip(0,15);
			};
			if(~circles.chordsBassCircle.blockedIndices.includes(index).not){

				/*{
				~circles.guiElements.notesHits.add(index);
				~circles.guiElements.noteHitColor = ev.guiColor.copy.alpha_(0.3);
				~circles.guiElements.notesView.refresh
				}.fork(AppClock);*/
				~toPhilipp.sendMsg("/bassIndex", index);
				(
					midinote: ~bassLine[index],
					dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
					legato: self.sharedValues.circleLegato,
					type: \oscMidi,
					chan: 2,
					netAddr: ~toBenni
				).play
			};
			~circles.chordsBassCircle.blockedIndices.add(index);
			thisThread.clock.sched(self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 16, {
				~circles.chordsBassCircle.blockedIndices.remove(index); nil
			});
		}
	};
};

~circles.chordsBassCircle.noteFunc.();
~circles.chordsBassCircle.sharedValues.monoMode = 1;
~circles.chordsBassCircle.sharedValues.freezeMe = true;
~circles.chordsBassCircle.sharedValues.makeOSCdefsForKeys((
	monoMode: { |val|
		if(val.asBoolean){
			~circles.chordsBassCircle.monoNoteFunc.();
		}{
			~circles.chordsBassCircle.noteFunc.();
		}
	}
));
~circles.chordsBassCircle.sharedValues.sendAll;
