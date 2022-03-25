// bildchen machen. wie kriegt man die taktart weg?
/*FoscConfiguration.lilypondExecutablePath = "/usr/bin/lilypond";
(0..127).do {|nn|
	a = FoscNote(nn, 1);
	a.writePNG("/home/vincent/Repos/bitrot/bitrot/pngs" +/+ nn ++ ".png", resolution: 75)
}*/

a = FoscStaff(FoscLeafMaker().(#[60], [1]));
m = FoscTimeSignature(#[3,8], hide: true);
a[0].attach(m);
a.show;
s
a = FoscStaff();
a.add(FoscLeafMaker().(#[60,62,64,65], [1/4]));
m = override(a);
// m.score.barline.visible = false
m.timesignature.visible = false
a.format;
a.show;

~circles.guiElements.notesView.refresh
~melodie = ~melodie.scramble
~melodie = 16.collect { 36 + 48.rand }
~circles.circleArray[0..2].do {|ev|
	ev.noteFunc = { |self, vel|
		var totalTaktDur = self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel;
		var taktStufe = thisThread.beats
		.mod(totalTaktDur / 4);
		// .round(self.sharedValues.quantVal.reciprocal);
		var index = ((
			(taktStufe / totalTaktDur) * 4
		) * 15.999);//.round.clip(0,15);//.asInteger;
		if(totalTaktDur <= 16){
			index = index.asInteger
		}{
			index = index.round.clip(0,15);
		};
		index.postln;
		~circles.guiElements.notesHits.add(index);
		{~circles.guiElements.notesView.refresh}.fork(AppClock);
		(
			midinote: ~melodie[index],
			dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
			legato: self.sharedValues.circleLegato,
			type: \midi,
			midiout: ~mOut
		).play
		//~toBenni.sendMsg("/circleNumber", self.circleNum, self.sharedValues.instrumentNum, vel);
	}
};
~circles.circleArray[1].guiColor.alpha_(0.5)
// variante 2, quasi mono synth
~circles.circleArray[0..2].do {|ev|
	ev.noteFunc = { |self, vel|
		// var melLength = 128;
		var totalTaktDur = self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel;
		var taktStufe = thisThread.beats
		.mod(totalTaktDur / 4);
		//.round(melLength.reciprocal);
		// .round(self.sharedValues.quantVal.reciprocal);
		var index = ((
			(taktStufe / (totalTaktDur)) * 4
		) * 15.999);//.asInteger;//.round.clip(0,15);
		//[index, index.asInteger, index.round.clip(0,15), totalTaktDur].postln;
		if(totalTaktDur < 16){
			index = index.asInteger
		}{
			index = index.round.clip(0,15);
		};
		if(~circles.lastMelodieNote != ~melodie[index]){
			if(~circles.lastMelodieNote.notNil){
				~mOut.noteOff(0, ~circles.lastMelodieNote);
			};
			~circles.guiElements.notesHits.add(index);
			{~circles.guiElements.notesView.refresh}.fork(AppClock);
			~mOut.noteOn(0, ~melodie[index], 70);
			~circles.lastMelodieNote = ~melodie[index];
		}
		//~toBenni.sendMsg("/circleNumber", self.circleNum, self.sharedValues.instrumentNum, vel);
	}
};