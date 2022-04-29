// network connection
// thisProcess.openUDPPort(8000); // philipp
// thisProcess.openUDPPort(9000); // receive port from rpi
// thisProcess.openUDPPort(9010); // receive port from open stage control
// ~rpiAddr = NetAddr("10.42.0.208", 9001); // send addr to rpi
/*~benniAddr = NetAddr("192.168.1.100", 8000); */// send addr to benni
// ~toBenni = NetAddr("192.168.1.104", 8000);
// ~localHost = NetAddr("127.0.0.1", 9001);

~circles = ();

~circles.circleArray = nil!7;

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

~circles.makeAngle = { |radius, circleNum, waitDur, guiColor, circleLegato = (1/8), muteEveryX = 0, circleParent|
	var symCircle = (circleParent ++ "Circle").asSymbol;
	var symNotesView = (circleParent ++ "NotesView").asSymbol;
	var ev = (
		sharedValues: OSCSharedEvent.new(netAddr: ~localHost, prefix: "circ" ++ circleNum),
		radius: radius,
		circumference: radius * 2,
		circleNum: circleNum,
		testAngle: 0,
		guiHit: 0,
		hits: Set.new,
		guiColor: guiColor,
		taktLen: 16,
		taktIndex: 0,
		arpCounter: 0,
		muteNow: false,
		muteCount: 0,
		waitRateNow: 0.1,
		getIntersections: { |self, angles| self.intersections = angles.select{|ang| ang[1] == self.radius} }
	);
	ev.sharedValues.fade = 0;
	ev.sharedValues.onOff = 0;
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
				Tdef(("circ" ++ circleNum).asSymbol).quant_(tdefQuant);
				Tdef(("circ" ++ circleNum).asSymbol, ev[\tdefLoopFunc]);
			}
		},
		loopSpeedLevel: {|newSpeed|
			if(ev.sharedValues.onOff.asBoolean){
				var tdefQuant = ev.sharedValues.waitDur * newSpeed / 4;
				Tdef(("circ" ++ circleNum).asSymbol).quant_(tdefQuant);
				Tdef(("circ" ++ circleNum).asSymbol, ev[\tdefLoopFunc]);
			}
		}
	));
	ev.sharedValues.sendAll;
	ev.tdefLoopFunc = {
		var copyWaitDur = ev.sharedValues.waitDur.copy; // diese soll nur quantisiert in effekt treten
		var copyLoopSpeedLevel = ev.sharedValues.loopSpeedLevel.copy;
		//"NEW LOOP STARTING".postln;
		ev.taktIndex = 0;
		loop {
			var waitRate;
			//var hits = Set.new;
			var circleSlice;
			ev.hits.clear;
			if(ev.taktIndex == 0){
				if(~circles[symCircle].sharedValues.noteArrayLen != ~circles[symCircle].taktLen){
					~circles[symCircle].taktLen = ~circles[symCircle].sharedValues.noteArrayLen.copy;
					{~circles.guiElements[symNotesView].refresh}.defer
				};
				if(ev.taktLen != ~circles[symCircle].taktLen){
					ev.taktLen = ~circles[symCircle].taktLen.copy;
				};
				if(ev.sharedValues.muteEveryX > 0){
					ev.muteNow = (ev.muteCount % ev.sharedValues.muteEveryX) == (ev.sharedValues.muteEveryX - 1);
					ev.muteCount = ev.muteCount + 1
				}{
					ev.muteNow = false
				}
			};
			waitRate = (copyWaitDur / 4 * copyLoopSpeedLevel) / ev.taktLen;
			ev.waitRateNow = waitRate;
			circleSlice = 360 / ev.taktLen;
			ev.testAngle = ev.taktIndex * circleSlice;

			// intersections in die taktIndices einteilen
			if(ev.intersections.notNil && ev.muteNow.not){
				ev.intersections.do {|ang, ix|
					ev.hits.add(
						ang[0]
						.linlin(0,360,0, ev.taktLen - 0.001)
						// .round(1)
						.clip(0, ev.taktLen - 1)
						.asInteger
					);
				};
				if(ev.hits.includes(ev.taktIndex)){
					// var velocityOfCircle = (i % 90).fold2(45).linlin(0,44,10,127);
					// var velocityOfClock = ~circles.quantAmps[thisThread.beats.mod(4)];
					ev.guiHit = 24;
					ev.noteFunc(100, ev.taktIndex);
				};
				// einer vor taktIndex
				if(ev.hits.includes((ev.taktIndex + 1) % ev.taktLen)){
					ev.sendIndexFunc((ev.taktIndex + 1) % ev.taktLen)
				};
				//[circleNum, hits, ev.taktIndex].postln;
			};
			ev.taktIndex = (ev.taktIndex + 1) % ev.taktLen;
			waitRate.wait;
		}
	};
	Tdef(("circ" ++ circleNum).asSymbol, ev[\tdefLoopFunc]);
	ev
};

["melodie", "bass", "melodie2"].do {|str|
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
	[~circles.melodieCircle, ~circles.bassCircle, ~circles.melodie2Circle].do { |instrumentCircle|
		if(instrumentCircle.sharedValues.freezeMe.asBoolean.not){
			instrumentCircle.points = points;
			instrumentCircle.circs.do {|ci| ci.getIntersections(angles)}
		};
	};
}, '/points').fix;
