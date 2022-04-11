~clipSequencer = (prefix: "clipSeq");
~clipSequencer.sharedEv = OSCSharedEvent.new(~localHost, ~clipSequencer.prefix);
~clipSequencer.sharedEv.loopDur = 4;
~clipSequencer.sharedEv.clipNum = 7;
~clipSequencer.sharedEv.linkFFTCa = 0;
~clipSequencer.sharedEv.tdefOnOff = 0;

~clipSequencer.sharedEv.makeOSCdefsForKeys((
	tdefOnOff: {|onOff|
		if(onOff.asBoolean){
			Tdef(\clipSeqLooper).play(quant: 1);
		}{
			Tdef(\clipSeqLooper).stop;
			// sollte hier der clip ausgeschaltet werden?
		};
	},
	linkFFTCa: {|onOff|
		if(onOff.asBoolean){
			~gameFFT.seedMe;
			{~gameFFT.pointerToWindow.visible_(true)}.fork(AppClock);
		}{
			{~gameFFT.pointerToWindow.visible_(false)}.fork(AppClock);
		};
	}
));

~clipSequencer.sharedEv.sendAll;

OSCdef((~clipSequencer.prefix ++ 'sendOff').asSymbol, { |msg|
	{~toBenni.sendMsg("/clips", 0)}.defer(TempoClock.timeToNextBeat);
},"/" +/+ ~clipSequencer.prefix +/+ "sendOff").fix;

OSCdef((~clipSequencer.prefix ++ 'sendOn').asSymbol, { |msg|
	{~toBenni.sendMsg("/clips", ~clipSequencer.sharedEv.clipNum)}.defer(TempoClock.timeToNextBeat);
},"/" +/+ ~clipSequencer.prefix +/+ "sendOn").fix;

Tdef(\clipSeqLooper, {
	loop {
		~toBenni.sendMsg("/clips", ~clipSequencer.sharedEv.clipNum);
		if(~clipSequencer.sharedEv.linkFFTCa.asBoolean){
			Pdefn(\caFFTNext).asStream.next;
		};
		~clipSequencer.sharedEv.loopDur.wait;
	}
});

Pdefn(\clipSequencer, r {
	var clipSeq = Pseq([1, 0, 1, 9,1, 0], inf).asStream;
	loop{
		~toBenni.sendMsg("/clips", clipSeq.next);
		0.yield;
}});

/*Pdefn(\clipSequencer, r {
	var clipSeq = Pwrand([5,2,1],[0.8,0.1,0.1], inf).asStream;
	loop{
		~toBenni.sendMsg("/clips", clipSeq.next);
		0.yield;
}});

Pdefn(\clipSequencer, r {
	var clipSeq = Pwrand([0,2,1],[0.8,0.1,0.1], inf).asStream;
	loop{
		~toBenni.sendMsg("/clips", clipSeq.next);
		0.yield;
}});*/
