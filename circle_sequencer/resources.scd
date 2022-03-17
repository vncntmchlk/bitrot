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
	//~offsetRight = Point(*msg[[5,6]]).postln;
},'/resolution').oneShot;

// ~linkClock = LinkClock.new(1).permanent_(true);

// ~mOut.noteOn(0, 36, 100)
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
		guiHit: 0,
		guiColor: guiColor,
		arpCounter: 0,
		muteNow: false,
		muteCount: 0,
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
		//ev.sharedValues.onOff = 1;
		inf.do {|i|
			ev.testAngle = i % 360;
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
						ev.guiHit = 24; // koennte anhand der velocity skalieren
						thisThread.clock.sched(quantCalc - thisThread.beats.mod(quantCalc),{
							var velocityOfCircle = (i % 90).fold2(45).linlin(0,44,10,127);
							var velocityOfClock = ~circles.quantAmps[thisThread.beats.mod(4)];
							//[ev.circleNum, ev.instrumentNum, velocityOfClock].postln;
							ev.noteFunc(velocityOfClock); // * ev.fadeObj.val
							nil // wichtig damit nicht nochmal gescheduled wird
						})
					}
				}
			};
			(ev.sharedValues.waitDur * ev.sharedValues.loopSpeedLevel / 1440).wait;
		}
	});

	ev
};

["melodie", "chordsBass"].do {|str| // "chordsBass", "arp"
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
	[~circles.melodieCircle, ~circles.chordsBassCircle].do { |instrumentCircle|
		if(instrumentCircle.sharedValues.freezeMe.asBoolean.not){
			instrumentCircle.points = points;
			instrumentCircle.circs.do {|ci| ci.getIntersections(angles)}
		};
	};
}, '/points').fix;