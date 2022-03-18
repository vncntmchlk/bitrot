~circles.circleArray[0] = ~circles[\makeAngle].(radius: 60, circleNum: 0, instrumentNum: 0, waitDur: 8, quantVal: 8, guiColor: Color.hsv(0,1,1));
~circles.circleArray[1] = ~circles[\makeAngle].(radius: 90, circleNum: 1, instrumentNum: 0, waitDur: 8, quantVal: 8, guiColor: Color.hsv(0.1,1,1));
~circles.circleArray[2] = ~circles[\makeAngle].(radius: 120, circleNum: 2, instrumentNum: 0, waitDur: 8, quantVal: 8, guiColor: Color.hsv(0.9,1,1));

~melodie = (60..75);

~circles.melodieCircle = (
	circs: ~circles.circleArray[0..2],
	sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "melodie"),
	points: [],
	guiText: "MELODIE"
);

~circles.melodieCircle.blockedIndices = Set.new();

// variante 2 mit note drawing
~circles.melodieCircle.monoNoteFunc = {
	~circles.circleArray[0..2].do {|ev|
		ev.noteFunc = { |self, vel|
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
			if(~circles.melodieCircle.blockedIndices.includes(index).not){
				~toPhilipp.sendMsg("/melodyIndex", index);
				if(~circles.lastMelodieNote != ~melodie[index]){
					if(~circles.lastMelodieNote.notNil){
						//~mOut.noteOff(0, ~circles.lastMelodieNote);
						~toBenni.sendMsg("notes0", ~circles.lastMelodieNote, 0);
					};
					~circles.guiElements.notesHits.add(index);
					{
						~circles.guiElements.noteHitColor = ev.guiColor.copy.alpha_(0.3);
						~circles.guiElements.notesView.refresh
					}.fork(AppClock);
					//~mOut.noteOn(0, ~melodie[index], 70);
					~toBenni.sendMsg("notes0", ~melodie[index], vel);
					~circles.lastMelodieNote = ~melodie[index];
				};
			};
			~circles.melodieCircle.blockedIndices.add(index);
			thisThread.clock.sched(self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 16, {
				~circles.melodieCircle.blockedIndices.remove(index); nil
			});
		}
	};
};
~circles.melodieCircle.noteFunc = {
	~circles.circleArray[0..2].do {|ev, circleIndex|
		ev.noteFunc = { |self, vel|
			var totalTaktDur = self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel;
			var taktStufe = thisThread.beats
			.mod(totalTaktDur / 4);
			var index = ((
				(taktStufe / (totalTaktDur)) * 4
			) * 15.999);//.asInteger;//.round.clip(0,15);
			var offsetMidinote = [-12, 0, 12][circleIndex];
			if(totalTaktDur < 16){
				index = index.asInteger
			}{
				index = index.round.clip(0,15);
			};
			if(~circles.melodieCircle.blockedIndices.includes(index).not){
				~toPhilipp.sendMsg("/melodyIndex", index);
				{
					~circles.guiElements.notesHits.add(index);
					~circles.guiElements.noteHitColor = ev.guiColor.copy.alpha_(0.3);
					~circles.guiElements.notesView.refresh
				}.fork(AppClock);
				(
					midinote: ~melodie[index] + offsetMidinote,
					dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
					legato: self.sharedValues.circleLegato,
					type: \oscMidi,
					chan: 0,
					netAddr: ~toBenni
				).play
			};
			~circles.melodieCircle.blockedIndices.add(index);
			thisThread.clock.sched(self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 16, {
				~circles.melodieCircle.blockedIndices.remove(index); nil
			});
		}
	};
};

~circles.melodieCircle.monoNoteFunc.();

~circles.melodieCircle.sharedValues.freezeMe = true;
~circles.melodieCircle.sharedValues.monoMode = 1;
~circles.melodieCircle.sharedValues.makeOSCdefsForKeys((
	monoMode: { |val|
		if(val.asBoolean){
			~circles.melodieCircle.monoNoteFunc.();
		}{
			~circles.melodieCircle.noteFunc.();
		}
	}
));
~circles.melodieCircle.sharedValues.sendAll;
