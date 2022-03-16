~circles.circleArray[0] = ~circles[\makeAngle].(radius: 60, circleNum: 0, instrumentNum: 0, waitDur: 8, quantVal: 8, guiColor: Color.hsv(0,1,1));
~circles.circleArray[1] = ~circles[\makeAngle].(radius: 90, circleNum: 1, instrumentNum: 0, waitDur: 8, quantVal: 8, guiColor: Color.hsv(0.1,1,1));
~circles.circleArray[2] = ~circles[\makeAngle].(radius: 120, circleNum: 2, instrumentNum: 0, waitDur: 8, quantVal: 8, guiColor: Color.hsv(0.9,1,1));

~melodie = (60..75);
// variante 1, viele noten auf einmal
/*~circles.circleArray[0..2].do {|ev|
ev.noteFunc = { |self, vel|
var taktStufe = thisThread.beats
.mod(self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4)
.round(self.sharedValues.quantVal.reciprocal);
var index = ((
(taktStufe / (self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel)) * 4
) * 15.999).asInteger;
index.postln;
(
midinote: ~melodie[index],
dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
legato: self.sharedValues.circleLegato,
type: \midi,
midiout: ~mOut
).play
//~toBenni.sendMsg("/circleNumber", self.circleNum, self.sharedValues.instrumentNum, vel);
}
};*/
// noteFuncs koennen so ersetzt werden und haben zugriff auf das self
// man koennte ausserdem pro circle individuelle notefuncs einbauen


// variante 2, quasi mono synth
/*~circles.circleArray[0..2].do {|ev|
ev.noteFunc = { |self, vel|
var taktStufe = thisThread.beats
.mod(self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4)
.round(self.sharedValues.quantVal.reciprocal);
var index = ((
(taktStufe / (self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel)) * 4
) * 15.999).asInteger;
index.postln;
if(~circles.lastMelodieNote != ~melodie[index]){
if(~circles.lastMelodieNote.notNil){
~mOut.noteOff(0, ~circles.lastMelodieNote);
};
~mOut.noteOn(0, ~melodie[index], 70);
~circles.lastMelodieNote = ~melodie[index];
}
//~toBenni.sendMsg("/circleNumber", self.circleNum, self.sharedValues.instrumentNum, vel);
}
};*/

// variante 2 mit note drawing
~circles.circleArray[0..2].do {|ev|
	ev.noteFunc = { |self, vel|
		var totalTaktDur = self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel;
		var taktStufe = thisThread.beats
		.mod(totalTaktDur / 4);
		var index = ((
			(taktStufe / (totalTaktDur)) * 4
		) * 15.999);//.asInteger;//.round.clip(0,15);
		if(totalTaktDur < 16){
			index = index.asInteger
		}{
			index = index.round.clip(0,15);
		};
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
		}
		//~toBenni.sendMsg("/circleNumber", self.circleNum, self.sharedValues.instrumentNum, vel);
	}
};

~circles.circleArray[0..2].do {|ev|
	ev.noteFunc = { |self, vel|
		var totalTaktDur = self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel;
		var taktStufe = thisThread.beats
		.mod(totalTaktDur / 4);
		var index = ((
			(taktStufe / (totalTaktDur)) * 4
		) * 15.999);//.asInteger;//.round.clip(0,15);
		if(totalTaktDur < 16){
			index = index.asInteger
		}{
			index = index.round.clip(0,15);
		};
		{
			~circles.guiElements.notesHits.add(index);
			~circles.guiElements.noteHitColor = ev.guiColor.copy.alpha_(0.3);
			~circles.guiElements.notesView.refresh
		}.fork(AppClock);
		(
			midinote: ~melodie[index],
			dur: self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 4,
			legato: self.sharedValues.circleLegato,
			type: \oscMidi,
			netAddr: ~toBenni
		).play
		//~toBenni.sendMsg("/circleNumber", self.circleNum, self.sharedValues.instrumentNum, vel);
	}
};

~circles.melodieCircle = (
	circs: ~circles.circleArray[0..2],
	sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "melodie"),
	points: [],
	guiText: "MELODIE"
);
~circles.melodieCircle.sharedValues.freezeMe = true;
~circles.melodieCircle.sharedValues.makeOSCdefsForKeys;
~circles.melodieCircle.sharedValues.sendAll;


// Tdef.all.do {|t| t.postln.release}