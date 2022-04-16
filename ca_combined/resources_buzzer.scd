// buzzer on und off.
// werte auf standard zurueck und bass anmachen
// werte auf standard zurueck und magic preset anmachen

~buzzerStuff = (
	sharedEv: OSCSharedEvent.new(~localHost, "buzzer"),
	resetValues: {
		topEnvironment[\toBenni].sendMsg("/clips", 0);
		topEnvironment[\toBenni].sendMsg("/bitrotData", "fftXbins", *[16, 32, 64, 128, 256]);
		topEnvironment[\toBenni].sendMsg("/bitrotData", "fftBinsGain", *[0, 0, 0, 0, 0, 0]);
		topEnvironment[\toBenni].sendMsg("/bitrotData", "xorBits", *[0,0,0,0,0,0,0,0,0,0]);
		topEnvironment[\toBenni].sendMsg("/bitrotData", "groupSRR", 1);
		topEnvironment[\toBenni].sendMsg("/bitrotData", "groupTrunc", 1)
	},
	nukeOnOff: 0,
	startNuke: { |self|
		self.nukeOnOff = 1;
		self.nukePbind = Pbind(
			\midinote, Pswitch1([
				Pstep([60,61,62,63],[1,1,1,1] * 1.5,inf),
				Pn(72)
			],Pseq([Pn(0,11),1],inf)).trace,
			\dur, Pwrand([1/8,1,3],[0.7,0.2,0.1],inf) * self.durMod,
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
				topEnvironment[\toBenni].sendMsg("/clips", 10.rand);
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
	stopNukeAndBass: { |self|
		self.nukeOnOff = 0;
		self.nukePbind.stop;
	}
);

~buzzerStuff.sharedEv.durMod = 1;
~buzzerStuff.sharedEv.nukePush = 0;

~buzzerStuff.sharedEv.makeOSCdefsForKeys((
	nukePush: {|val|
		if(~buzzerStuff.nukeOnOff.asBoolean){
			~buzzerStuff.stopNuke
		}{
			~buzzerStuff.startNuke
		}
	}
));
