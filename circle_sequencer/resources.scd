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

~circles.makeAngle = { |radius, circleNum, waitDur, guiColor, circleLegato = (1/8), muteEveryX = 0|
	var ev = (
		sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "circ" ++ circleNum),
		radius: radius,
		circumference: radius * 2,
		circleNum: circleNum,
		testAngle: 0,
		guiHit: 0,
		guiColor: guiColor,
		taktIndex: 0,
		noteArrayLen: 16,
		arpCounter: 0,
		muteNow: false,
		muteCount: 0,
		getIntersections: { |self, angles| self.intersections = angles.select{|ang| ang[1] == self.radius} }
	);
	ev.sharedValues.fade = 0;
	ev.sharedValues.onOff = 0;
	//ev.sharedValues.quantVal = quantVal;
	ev.sharedValues.waitDur = waitDur;
	ev.sharedValues.loopSpeedLevel = 1;
	ev.sharedValues.circleLegato = circleLegato; // 1/4 ganz, 1/8 halb ..
	ev.sharedValues.muteEveryX = muteEveryX;
	ev.sharedValues.makeOSCdefsForKeys((
		onOff: {|onOff|
			if(onOff.asBoolean){
				var tdefQuant = ev.sharedValues.waitDur * ev.sharedValues.loopSpeedLevel / 4;
				ev.taktIndex = 0;
				Tdef(("circ" ++ circleNum).asSymbol).play(TempoClock.default, doReset: true, quant: [tdefQuant,0,-0.025]);
			}{
				Tdef(("circ" ++ circleNum).asSymbol).stop
			};
		},
		waitDur: {|newWaitDur|
			if(ev.sharedValues.onOff.asBoolean){
				var tdefQuant = newWaitDur * ev.sharedValues.loopSpeedLevel / 4;
				ev.taktIndex = 0;
				Tdef(("circ" ++ circleNum).asSymbol).stop;
				Tdef(("circ" ++ circleNum).asSymbol).play(TempoClock.default, doReset: true, quant: [tdefQuant,0,-0.025]);
			}
		},
		loopSpeedLevel: {|newSpeed|
			if(ev.sharedValues.onOff.asBoolean){
				var tdefQuant = ev.sharedValues.waitDur * newSpeed / 4;
				ev.taktIndex = 0;
				Tdef(("circ" ++ circleNum).asSymbol).stop;
				Tdef(("circ" ++ circleNum).asSymbol).play(TempoClock.default, doReset: true, quant: [tdefQuant,0,-0.025]);
			}
		}
	));
	ev.sharedValues.sendAll;

	Tdef(("circ" ++ circleNum).asSymbol, {
		inf.do {|i|
			var waitRate = (ev.sharedValues.waitDur / 4 * ev.sharedValues.loopSpeedLevel) / ev.noteArrayLen;
			var hits = Set.new;
			// auch noch ein hits Set fuer melodiecircle usw. ?

			ev.testAngle = ev.taktIndex * 22.5;
			// 360 / 16
			if(ev.taktIndex == 0){
				if(ev.sharedValues.muteEveryX > 0){
					ev.muteNow = (ev.muteCount % ev.sharedValues.muteEveryX) == (ev.sharedValues.muteEveryX - 1);
					ev.muteCount = ev.muteCount + 1
				}{
					ev.muteNow = false
				}
			};

			// intersections in die taktIndices einteilen
			if(ev.intersections.notNil && ev.muteNow.not){
				ev.intersections.do {|ang, ix|
					hits.add(
						ang[0]
						.linlin(0,360,0, ev.noteArrayLen - 0.001)
						.round(1)
						.clip(0, ev.noteArrayLen - 1)
						.asInteger
					);
				};
				if(hits.includes(ev.taktIndex)){
					// var velocityOfCircle = (i % 90).fold2(45).linlin(0,44,10,127);
					// var velocityOfClock = ~circles.quantAmps[thisThread.beats.mod(4)];
					ev.guiHit = 24;
					ev.noteFunc(100, ev.taktIndex);
				};
				// einer vor taktIndex
				if(hits.includes((ev.taktIndex + 1) % ev.noteArrayLen)){
					ev.sendIndexFunc((ev.taktIndex + 1) % ev.noteArrayLen)
				};
				//[circleNum, hits, ev.taktIndex].postln;
			};
			ev.taktIndex = (ev.taktIndex + 1) % ev.noteArrayLen;
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
		// angles.postln
	};
	[~circles.melodieCircle, ~circles.bassCircle, ~circles.chordsCircle].do { |instrumentCircle|
		if(instrumentCircle.sharedValues.freezeMe.asBoolean.not){
			instrumentCircle.points = points;
			instrumentCircle.circs.do {|ci| ci.getIntersections(angles)}
		};
	};
}, '/points').fix;
