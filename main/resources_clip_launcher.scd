var prefix =  "clipSeq";
~clipSequencer = (prefix: prefix);
~clipSequencer.sharedEv = OSCSharedEvent.new(~localHost, ~clipSequencer.prefix);
~clipSequencer.sharedEv.loopDur = 4;
~clipSequencer.sharedEv.clipNum = 7;
~clipSequencer.sharedEv.linkFFTCa = 0;
~clipSequencer.sharedEv.tdefOnOff = 0;

~clipSequencer.presetManager = ~makePresetManager.(prefix,["~clipSequencer.sharedEv"]);

// Buzzer stuff
~clipSequencer.sharedEv.durMod = 1;

~clipSequencer.sharedEv.stopMode = 0;
~buzzerStuff = (
	resetValues: {
		topEnvironment[\toBenni].sendMsg("/clips", 0);
		topEnvironment[\toBenni].sendMsg("/bitrotData", "fftXbins", *[4, 8, 16, 32, 64]); //[16, 32, 64, 128, 256]
		topEnvironment[\toBenni].sendMsg("/bitrotData", "fftBinsGain", *[0, 0, 0, 0, 0, 0]);
		topEnvironment[\toBenni].sendMsg("/bitrotData", "xorBits", *[0,0,0,0,0,0,0,0,0,0]);
		topEnvironment[\toBenni].sendMsg("/bitrotData", "groupSRR", 1);
		topEnvironment[\toBenni].sendMsg("/bitrotData", "groupTrunc", 1)
	},
	nukeOnOff: 0,
	startNuke: { |self|
		self.nukeOnOff = 1;
		self.nukePbind = Pbind(
			\dur, Pwrand([1/8,1,3],[0.7,0.2,0.1],inf) * Pfunc {~clipSequencer.sharedEv.durMod},
			\rest, Rest(1),
			\fftXbins, Pfunc{[16, 32, 64, 128, 256].scramble},
			\fftBinsGain, Pfunc{ 6.collect{ 22.0.rand} },
			\fftBinsDenoise, Pfunc{ 6.collect{ 52.0.rand * -1} },
			\grainStart_Looplength_Scanspeed, Pfunc { [500 + 3000.rand, 50.rand, 100.rand] },
			\freezeGrains, Pfunc { 2.rand },
			\xorBits, Pfunc{[1,1,0,0,0,0,0,0,0,0].scramble},
			\groupSRR, Pwhite(0,1),
			\groupTrunc,Pseq([0,0.5,1],inf),// Pn(Pgeom(0.1, 1.1, 20)),
			\finish, { |ev|
				topEnvironment[\toBenni].sendMsg("/clips", 1 + 10.rand);
				topEnvironment[\toBenni].sendMsg("/bitrotData", "fftXbins", *ev.fftXbins);
				topEnvironment[\toBenni].sendMsg("/bitrotData", "fftBinsGain", *ev.fftBinsGain);
				topEnvironment[\toBenni].sendMsg("/bitrotData", "xorBits", *ev.xorBits);
				topEnvironment[\toBenni].sendMsg("/bitrotData", "groupSRR", ev.groupSRR);
				topEnvironment[\toBenni].sendMsg("/bitrotData", "groupTrunc", ev.groupTrunc.clip(0, 1))
			}
		).play(quant: 0);
	},
	stopNuke: { |self|
		self.nukeOnOff = 0;
		self.nukePbind.stop;
	},
	stopNukeAndReset: { |self|
		self.nukeOnOff = 0;
		self.nukePbind.stop;
		self.resetValues
	},
	nukePressFunction: {
		"Buzzer PRESSED".postln;
		if(~buzzerStuff.nukeOnOff.asBoolean){
			switch(~clipSequencer.sharedEv.stopMode.asInteger)
			{0}{~buzzerStuff.stopNuke}
			{1}{~buzzerStuff.stopNukeAndReset}
			{2}{
				~buzzerStuff.stopNukeAndReset;
				~toBenni.sendMsg("/clips", 2);
			}
			{3}{ // random Clip
				~buzzerStuff.stopNukeAndReset;
				~toBenni.sendMsg("/clips", (1+(13.rand)));
			}
			{4}{ // ubahn
				~buzzerStuff.stopNukeAndReset;
				~toBenni.sendMsg("/clips", 7);
			}

		}{
			~buzzerStuff.startNuke
		}
	}
);

OSCdef(\nukePush, {~buzzerStuff[\nukePressFunction].value}, '/nukePush').fix;

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
		~gameFFT[\windowOnOff].(onOff.asBoolean, prefix.asSymbol);
		if(onOff.asBoolean){
			~gameFFT.seedMe;
			~gameFFT.sharedEv.tdefOnOff = 0;
		};
	},
	/*	nukePush: {|val|
	if(~buzzerStuff.nukeOnOff.asBoolean){
	switch(~clipSequencer.sharedEv.stopMode.asInteger)
	{0}{~buzzerStuff.stopNuke}
	{1}{~buzzerStuff.stopNukeAndReset}
	{2}{
	~buzzerStuff.stopNukeAndReset;
	~toBenni.sendMsg("/clips", 2);
	}
	{3}{ // random Clip
	~buzzerStuff.stopNukeAndReset;
	~toBenni.sendMsg("/clips", (1+(13.rand)));
	}
	{4}{ // ubahn
	~buzzerStuff.stopNukeAndReset;
	~toBenni.sendMsg("/clips", 7);
	}

	}{
	~buzzerStuff.startNuke
	}
	}*/
));

/*{
"ubahn": 1,
"all off": 0,
"bass solo": 2
}*/

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
