Event.addEventType(\oscMidi, {
	var freqs, lag, dur, sustain, strum;
	var bndl, hasGate, netAddr;

	netAddr = ~netAddr;

	freqs = ~freq = ~detunedFreq.value;

	~amp = ~amp.value;
	~midinote = (freqs.cpsmidi).round(1).asInteger;
	strum = ~strum;
	lag = ~lag;
	sustain = ~sustain = ~sustain.value;
	hasGate = ~hasGate ? true;

	bndl = { arg chan=0, midinote=60, amp=0.1;
		[chan, midinote, asInteger((amp * 127).clip(0, 127)) ] }.valueEnvir.asCollection;

	//[chan, midinote, asInteger((amp * 127).clip(0, 127)) ]

	bndl = bndl.asControlInput.flop;
	// msgArgs = [chan, midinote, veloc]
	bndl.do {|msgArgs, i|
		var latency;

		latency = i * strum + lag;

		if(latency == 0.0) {
			("noteOn " ++ msgArgs).postln;
			~netAddr.sendMsg("notes" ++ msgArgs[0], *msgArgs[[1,2]]);
		} {
			thisThread.clock.sched(latency, {
				("noteOn " ++ msgArgs).postln;
				~netAddr.sendMsg("notes" ++ msgArgs[0], *msgArgs[[1,2]]);
			})
		};
		if(hasGate) {
			thisThread.clock.sched(sustain + latency, {
				("noteOff " ++ msgArgs).postln;
				//~netAddr.sendMsg("notes" ++ msgArgs[0], *[msgArgs[1], 0]);
			});
		};
	};
}, Event.parentEvents.default.copy.putAll((legato:1)));
n = NetAddr("127.0.0.1", 8080)
Pbind(\type, \oscMidi, \chan, 13, \midinote,36, \db, -10, \netAddr, ~toBenni).play