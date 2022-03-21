// network connection
// thisProcess.openUDPPort(8000); // philipp
// thisProcess.openUDPPort(9000); // receive port from rpi
// thisProcess.openUDPPort(9010); // receive port from open stage control
// ~rpiAddr = NetAddr("10.42.0.208", 9001); // send addr to rpi
/*~benniAddr = NetAddr("192.168.1.100", 8000); */// send addr to benni
// ~toBenni = NetAddr("192.168.1.104", 8000);
// ~localHost = NetAddr("127.0.0.1", 9001);

~circles = ();

~circles.circleArray = nil!6;

~circles.guiElements ?? {~circles.guiElements = ()};
~circles.guiElements.offset = Point( 196, 135 ); //wird auch fuer rechts benutzt...
OSCdef(\resolution, { |msg|
	~circles.guiElements.resolution = msg[[1,2]].postln;
	~circles.guiElements.offset = Point(*msg[[3,4]]).postln;
},'/resolution').oneShot;

{
	var amps = (4: 127, 8: 70, 16: 45);
	~circles.quantAmps = Env([
		amps[4],amps[16],amps[8],amps[16],
		amps[4],amps[16],amps[8],amps[16],
		amps[4],amps[16],amps[8],amps[16],
		amps[4],amps[16],amps[8],amps[16],amps[4]
	],[1/4],[-4,4]);
}.value;

~circles.makeAngle = { |radius, circleNum, instrumentNum, waitDur, quantVal = 4, guiColor, circleLegato = (1/8), muteEveryX = 0|
	var ev = (
		sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "circ" ++ circleNum),
		/*fadeObj: (
		val: 1,
		fadeTime: 5,
		inc: {|self|
		self.player.stop;
		self.player = {
		while {self.val <= 1}{ self.val = (self.val + 0.01); (self.fadeTime * 0.01).wait }
		}.fork
		},
		dec: {|self|
		self.player.stop;
		self.player = {
		while {self.val >= 0.001}{ self.val = (self.val - 0.01).round(0.01); (self.fadeTime * 0.01).wait };
		if(ev.sharedValues.onOff.asBoolean.not){Tdef(("circ" ++ circleNum).asSymbol).stop};
		}.fork
		}
		),*/
		radius: radius,
		circumference: radius * 2,
		circleNum: circleNum,
		testAngle: 0,
		testAngleLookAhead: 0,
		guiHit: 0,
		guiColor: guiColor,
		arpCounter: 0,
		muteNow: false,
		muteCount: 0,
		//muteNowLookAhead: false,
		//muteCountLookAhead: false,
		lookAheadTime: 0.02, // nicht groesser als 0.03125 (self.sharedValues.waitDur * self.sharedValues.loopSpeedLevel / 16)
		// wird durch tempoclock aenderungen noch ein andere wert rauskommen
		getIntersections: { |self, angles| self.intersections = angles.select{|ang| ang[1] == self.radius} }
	);
	ev.sharedValues.fade = 0;
	ev.sharedValues.onOff = 0;
	ev.sharedValues.quantVal = quantVal;
	ev.sharedValues.waitDur = waitDur;
	ev.sharedValues.loopSpeedLevel = 1;
	ev.sharedValues.instrumentNum = instrumentNum;
	ev.sharedValues.circleLegato = circleLegato; // 1/4 ganz, 1/8 halb ..
	ev.sharedValues.muteEveryX = muteEveryX;
	ev.sharedValues.makeOSCdefsForKeys((
		onOff: {|onOff|
			if(onOff.asBoolean){
				var tdefQuant = ev.sharedValues.waitDur * ev.sharedValues.loopSpeedLevel / 4;
				Tdef(("circ" ++ circleNum).asSymbol).play(TempoClock.default, doReset: true, quant: [tdefQuant,0,-0.025]);
			}{
				Tdef(("circ" ++ circleNum).asSymbol).stop
			};
		},
		waitDur: {|newWaitDur|
			if(ev.sharedValues.onOff.asBoolean){
				var tdefQuant = newWaitDur * ev.sharedValues.loopSpeedLevel / 4;
				Tdef(("circ" ++ circleNum).asSymbol).stop;
				Tdef(("circ" ++ circleNum).asSymbol).play(TempoClock.default, doReset: true, quant: [tdefQuant,0,-0.025]);
			}
		},
		loopSpeedLevel: {|newSpeed|
			if(ev.sharedValues.onOff.asBoolean){
				var tdefQuant = ev.sharedValues.waitDur * newSpeed / 4;
				Tdef(("circ" ++ circleNum).asSymbol).stop;
				Tdef(("circ" ++ circleNum).asSymbol).play(TempoClock.default, doReset: true, quant: [tdefQuant,0,-0.025]);
			}
		}
	));
	ev.sharedValues.sendAll;

	Tdef(("circ" ++ circleNum).asSymbol, {
		inf.do {|i|
			var waitRate = (ev.sharedValues.waitDur * ev.sharedValues.loopSpeedLevel / 1440);
			var lookAheadIndex = (ev.lookAheadTime / waitRate).asInteger.clip(1, 359);
			// waitDur minimum = 1, loopSpeed = 0.5
			// ziel: 0.02 sek vorher zu philipp schicken
			// ev.testAngleLookAhead = (i + lookAheadIndex) % 360;
			// es wird immer ca. 0.02 sekunden vorher geschaut (tempoclock aenderungen koennten einfluss haben?)
			// der index wird direkt zu philipp geschickt, die notefunc mit der entsprechenden verzoegerung gefeuert
			// (berechnet aus dauer eines taktIndexes (gesamt taktdauer / 16) minus look ahead time
			ev.testAngle = i % 360;
			// ev.testAngleLookAhead = (i + lookAheadIndex) % 360;
			// bei jedem neuen Durchlauf vom Kreis
			if(ev.testAngle == 0){
				if(ev.sharedValues.muteEveryX > 0){
					ev.muteNow = (ev.muteCount % ev.sharedValues.muteEveryX) == (ev.sharedValues.muteEveryX - 1);
					ev.muteCount = ev.muteCount + 1
				}{
					ev.muteNow = false
				}
			};

			if(ev.intersections.notNil && ev.muteNow.not){
				ev.intersections.do { |ang, ix|
					if(ang[0].asInteger == ev.testAngle){
						var quantCalc = 1 / ev.sharedValues.quantVal;
						var schedCalc = quantCalc - thisThread.beats.mod(quantCalc);
						var retIndex = ev.sendIndexFunc(schedCalc);
						if(retIndex.notNil){
							ev.guiHit = 24;
							// hier evtl ein minimum fuer schedCalc einfuegen damit philipp auf jeden fall zum zuge kommt
							// mach dann mal bench bei ihm um zu sehen ob seine response funktion nicht zu langsam ist ...
							thisThread.clock.sched(schedCalc,{
								var velocityOfCircle = (i % 90).fold2(45).linlin(0,44,10,127);
								var velocityOfClock = ~circles.quantAmps[thisThread.beats.mod(4)];
								ev.noteFunc(velocityOfClock, retIndex); // * ev.fadeObj.val
								nil // wichtig damit nicht nochmal gescheduled wird
							})
						};
					}
				}
			};
			waitRate.wait;
		}
	});
	ev
};

["melodie", "bass", "chords"].do {|str|
	("instrumentCircles" +/+ str ++ ".scd").loadRelative
};

OSCdef(\points,{|msg|
	var points = msg[1..].clump(2);
	var angles;
	if(points.notEmpty){
		angles = points.collect {|p|
			[Point(p[0], p[1]).translate(~circles.guiElements.offset * -1).theta.raddeg + 180, Point(p[0], p[1]).dist(~circles.guiElements.offset).round]
		};
	};
	[~circles.melodieCircle, ~circles.bassCircle, ~circles.chordsCircle].do { |instrumentCircle|
		if(instrumentCircle.sharedValues.freezeMe.asBoolean.not){
			instrumentCircle.points = points;
			instrumentCircle.circs.do {|ci| ci.getIntersections(angles)}
		};
	};
}, '/points').fix;
