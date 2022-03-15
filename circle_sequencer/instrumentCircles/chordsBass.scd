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
~circles.chordsBassCircle.sharedValues.freezeMe = true;
~circles.chordsBassCircle.sharedValues.makeOSCdefsForKeys;
~circles.chordsBassCircle.sharedValues.sendAll;