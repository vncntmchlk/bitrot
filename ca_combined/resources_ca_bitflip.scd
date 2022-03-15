
~caBitFlip = { |initCaSize = 8, initLastValuesSize = 10, startRules = 30|
	var win, game, gameBlockSize = 40;
	var newCaSize, newLastValuesSize;
	var prefix = "bitflip";
	var sharedEv = OSCSharedEvent.new(~localHost, prefix);

	sharedEv.caSize = initCaSize;
	sharedEv.lastValuesSize = initLastValuesSize;
	sharedEv.currentRule = startRules;
	sharedEv.sendRate = 2;
	sharedEv.blendSteps = 10;
	sharedEv.caRange = [0, 9];
	sharedEv.tdefOnOff = 0;

	win = Window.new(bounds: (initCaSize * gameBlockSize)@((initLastValuesSize + 1) * gameBlockSize)).front;
	win.view.background_(Color.black);
	win.drawFunc = {
		var cols = sharedEv.caSize, rows = sharedEv.lastValuesSize;
		cols.do{ |col|
			rows.do { |row|
				Pen.color = Color.gray(game.lastValues[row][col]);
				Pen.addRect(
					Rect(col * gameBlockSize, row * gameBlockSize, gameBlockSize, gameBlockSize)
				);
				Pen.fill;
			}
		};
		game.colSums.do {|val, col|
			if(col >= game.relevantCa[0] and: {col < game.relevantCa[1]}){ // nicht benutze spalten ueberspringen
				Pen.color = Color.gray(val);
				Pen.addRect(
					Rect(col * gameBlockSize, rows * gameBlockSize, gameBlockSize, gameBlockSize)
				);
				Pen.fill;
			}
		};

		// nicht benutze spalten abdunkeln
		Pen.addRect(Rect(0, 0, game.relevantCa[0] * gameBlockSize, rows * gameBlockSize));
		Pen.fillAxialGradient(Point(), Point(game.relevantCa[0] * gameBlockSize, 0), Color.gray(0, 1), Color.gray(0, 0.333));

		Pen.addRect(Rect(game.relevantCa[1] * gameBlockSize,0, (sharedEv.caSize - game.relevantCa[1]) * gameBlockSize, rows * gameBlockSize));
		Pen.fillAxialGradient(Point(game.relevantCa[1] * gameBlockSize, 0), Point(sharedEv.caSize * gameBlockSize, 0), Color.gray(0, 0.333), Color.gray(0, 1));
	};

	game = (
		sharedEv: sharedEv,
		lastValues: (0 ! initCaSize) ! initLastValuesSize,
		saveLastValuesSize: initLastValuesSize,
		myGen: (0!initCaSize).put((initCaSize * 0.5).round, 1),
		seedMe: { |self| self.myGen = (0!sharedEv.caSize).put((sharedEv.caSize * 0.5).round, 1)},
		killSwitch: { |self| self.myGen = (0!sharedEv.caSize)},
		resizeWindow: { |self|
			win.bounds_(
				Rect(
					win.bounds.left,
					win.bounds.top,
					sharedEv.caSize * gameBlockSize,
					(sharedEv.lastValuesSize + 1) * gameBlockSize
				)
			)
		},
		// diese beiden funktionen muessen ohne self auskommen damit die connected werden koennen zum sharedEv
		newCaSize: { |newSize = 8|
			sharedEv.caSize = newSize;
			game.lastValues = (0 ! sharedEv.caSize) ! sharedEv.lastValuesSize; // was war kopieren?
			game.myGen = 0 ! sharedEv.caSize; // das vorhandene kopieren ..
			game.seedMe;
			game.sumColums; // das ist wahrscheinlich notwendig?
			game[\onlyShow].(sharedEv.caRange);
			// resize window ..
			{game.resizeWindow}.fork(AppClock);
		},
		newLastValuesSize: { |newSize = 10|
			if(newSize != game.saveLastValuesSize){
				[newSize, game.saveLastValuesSize].postln;
				if(newSize < game.saveLastValuesSize){
					game.lastValues = game.lastValues[..(newSize - 1)]
				}{
					game.lastValues = game.lastValues[..(newSize - 1)] ++ (
						(0 ! sharedEv.caSize) ! (newSize - game.saveLastValuesSize)
					)
				};
				game.saveLastValuesSize = newSize;
				sharedEv.lastValuesSize = newSize;
				game.sumColums;
				// resize window ..
				{game.resizeWindow}.fork(AppClock);
			}
		},
		nextGen: { |self, visualize = true|
			self.myGen = self.myGen.collect { |val index|
				var left = self.myGen.wrapAt(index - 1),
				right = self.myGen.wrapAt(index + 1);
				self.rules[
					[left,val,right].reduce{|a b| a.asString ++ b.asString}.asSymbol
				];
			};
			self.lastValues = self.lastValues.shift(1, self.myGen);
			self.sumColumns;
			if(visualize){self.visualize};
			0
		},
		sumColumns: { |self|
			self.colSums = self.lastValues.flop.collect {|col|
				(col.sum / sharedEv.lastValuesSize)
			}
		},
		visualize: { |self|
			{win.refresh}.fork(AppClock)
		},
		makeRules: { |num|
			var arr = num.asBinaryDigits.reverse;
			("rule " ++ num).postln;
			sharedEv.currentRule = num;
			game.rules = (
				'000': arr[0],
				'001': arr[1],
				'010': arr[2],
				'011': arr[3],
				'100': arr[4],
				'101': arr[5],
				'110': arr[6],
				'111': arr[7]
			)
		},
		onlyShow: { |range|
			var caMid = (sharedEv.caSize / 2).asInteger;
			var relevantSize = range[1] - range[0] + 1;
			var start = caMid - 5 + range[0]; //(relevantSize / 2).asInteger;
			var end = start + relevantSize;
			game.delayedCaRange = range; // necessary for Tdef
			game.relevantCa = [start, end]
		}
	);

	game[\onlyShow].(sharedEv.caRange);
	game[\makeRules].(startRules);

	sharedEv.makeOSCdefsForKeys((
		caSize: game[\newCaSize],
		lastValuesSize: game[\newLastValuesSize],
		currentRule: game[\makeRules],
		caRange: game[\onlyShow],
		tdefOnOff: {|onOff|
			if(onOff.asBoolean){
				Tdef(\bitflip).play(quant: 1)
			}{
				Tdef(\bitflip).stop
			};
			sharedEv.tdefOnOff = onOff;
		}
	));
	sharedEv.sendAll;

	// seedMe and killswitch OSCdefs
	OSCdef((prefix ++ 'seedMe').asSymbol, { |msg|
		if(msg[1].asBoolean){game.seedMe}
	},"/" +/+ prefix +/+ "seedMe").fix;

	OSCdef((prefix ++ 'killSwitch').asSymbol, { |msg|
		if(msg[1].asBoolean){game.killSwitch}
	},"/" +/+ prefix +/+ "killSwitch").fix;

	game
};

Tdef(\bitflip, {
	var lastColSums = 0 ! ~gameBitFlip.sharedEv.caSize;
	var nextColSums;
	var bitDummy = 0!10;
	var sendArray;
	var calcBitFlips = {
		var res = bitDummy.copy;
		~gameBitFlip.colSums[~gameBitFlip.relevantCa[0]..(~gameBitFlip.relevantCa[1] - 1)].do {|v, ix|
			res[ix + ~gameBitFlip.delayedCaRange[0]] = v
		};
		res
	};
	loop {
		var blendSteps = ~gameBitFlip.sharedEv.blendSteps;
		var sendRate = ~gameBitFlip.sharedEv.sendRate; // Hz
		if(blendSteps > 1){
			var waitTime = (sendRate * blendSteps).reciprocal;
			~gameBitFlip.nextGen(false);
			nextColSums = ~gameBitFlip.colSums;
			blendSteps.do { |step|
				var blendedColSums = lastColSums.blend(nextColSums, step / blendSteps);
				~gameBitFlip.colSums = blendedColSums.round(1).asInteger;
				~gameBitFlip.visualize;
				sendArray = calcBitFlips.();
				~toBenni.sendMsg("/bitrotData", *(["xorBits"] ++ sendArray));
				waitTime.wait;
			};
			lastColSums = nextColSums;
		}{
			~gameBitFlip.nextGen(false);
			~gameBitFlip.colSums = ~gameBitFlip.colSums.round(1).asInteger;
			~gameBitFlip.visualize;
			sendArray = calcBitFlips.();
			~toBenni.sendMsg("/bitrotData", *(["xorBits"] ++ sendArray));
			sendRate.reciprocal.wait;
		}
	}
});

Pdefn(\bitflipNext, Routine {
	var lastColSums = 0 ! ~gameBitFlip.sharedEv.caSize;
	var nextColSums;
	var bitDummy = 0!10;
	var sendArray;
	var calcBitFlips = {
		var res = bitDummy.copy;
		~gameBitFlip.colSums[~gameBitFlip.relevantCa[0]..(~gameBitFlip.relevantCa[1] - 1)].do {|v, ix|
			res[ix + ~gameBitFlip.delayedCaRange[0]] = v
		};
		res
	};
	loop {
		~gameBitFlip.nextGen;
		~gameBitFlip.colSums = ~gameBitFlip.colSums.round(1).asInteger;
		sendArray = calcBitFlips.();
		~toBenni.sendMsg("/bitrotData", *(["xorBits"] ++ sendArray));
		1.yield;
	}
});

/*Tdef(\fftBinsGainSmooth, {
var lastColSums = 0 ! ~gameBitFlip.sharedEv.caSize;
var nextColSums;
var sendDb;
var dbArr = [
[-15, 12],
[-9, 21],
[-21, 21],
[-27, 21],
[-36, 21],
[-9, 36]
];
var emphasizeMidSection = Env.new([0,0.5,1],[0.5,0.5],[5, -5]);
loop {
var blendSteps = ~gameBitFlip.sharedEv.blendSteps;
var sendRate = ~gameBitFlip.sharedEv.sendRate; // Hz
if(~gameBitFlip.sharedEv.blendSteps > 1){
var waitTime = (~gameBitFlip.sharedEv.sendRate * blendSteps).reciprocal;
~gameBitFlip.nextGen(false);
nextColSums = ~gameBitFlip.colSums;
blendSteps.do { |step|
var blendedColSums = lastColSums.blend(nextColSums, step / blendSteps);
~gameBitFlip.colSums = blendedColSums;
~gameBitFlip.visualize; //~game.visualize(false);
sendDb = ~gameBitFlip.colSums[~gameBitFlip.relevantCa[0]..(~gameBitFlip.relevantCa[1] - 1)].collect {|v, ix|
v = emphasizeMidSection[v];
v.linlin(0, 1, dbArr[ix][0], dbArr[ix][1])
};
// sendDb = ~gameBitFlip.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, dbArr[ix][0], dbArr[ix][1], -4)};
~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
waitTime.wait;
};
lastColSums = nextColSums;
}{
~gameBitFlip.nextGen;
sendDb = ~gameBitFlip.colSums[~gameBitFlip.relevantCa[0]..(~gameBitFlip.relevantCa[1] - 1)].collect {|v, ix|
v = emphasizeMidSection[v];
v.linlin(0, 1, dbArr[ix][0], dbArr[ix][1])
};
// sendDb = ~gameBitFlip.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, dbArr[ix][0], dbArr[ix][1], -4)};
~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
sendRate.reciprocal.wait;
}
}
})*/

/* hier bins MIN, variablen muessen noch umbenannt werden
Tdef(\fftBinsMin, {
var lastColSums = 0 ! ~gameBitFlip.sharedEv.caSize;
var nextColSums;
var sendDb;
var dbArr = [
[0, 6],
[0, 5],
[0, 4],
[0, 3],
[0, 2],
[0, 1]
];
var emphasizeMidSection = Env.new([0,0.5,1],[0.5,0.5],[5, -5]);
loop {
var blendSteps = ~gameBitFlip.sharedEv.blendSteps;
var sendRate = ~gameBitFlip.sharedEv.sendRate; // Hz
if(~gameBitFlip.sharedEv.blendSteps > 1){
var waitTime = (~gameBitFlip.sharedEv.sendRate * blendSteps).reciprocal;
~gameBitFlip.nextGen(false);
nextColSums = ~gameBitFlip.colSums;
blendSteps.do { |step|
var blendedColSums = lastColSums.blend(nextColSums, step / blendSteps);
~gameBitFlip.colSums = blendedColSums;
~gameBitFlip.visualize; //~game.visualize(false);
sendDb = ~gameBitFlip.colSums[~gameBitFlip.relevantCa[0]..(~gameBitFlip.relevantCa[1] - 1)].collect {|v, ix|
v = emphasizeMidSection[v];
v.linlin(0, 1, dbArr[ix][0], dbArr[ix][1])
};
// sendDb = ~gameBitFlip.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, dbArr[ix][0], dbArr[ix][1], -4)};
~toBenni.sendMsg("/bitrotData", "fftBinsMin", *sendDb);
waitTime.wait;
};
lastColSums = nextColSums;
}{
~gameBitFlip.nextGen;
sendDb = ~gameBitFlip.colSums[~gameBitFlip.relevantCa[0]..(~gameBitFlip.relevantCa[1] - 1)].collect {|v, ix|
v = emphasizeMidSection[v];
v.linlin(0, 1, dbArr[ix][0], dbArr[ix][1])
};
// sendDb = ~gameBitFlip.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, dbArr[ix][0], dbArr[ix][1], -4)};
~toBenni.sendMsg("/bitrotData", "fftBinsMin", *sendDb);
sendRate.reciprocal.wait;
}
}
})
*/
