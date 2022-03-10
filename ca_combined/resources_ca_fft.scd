~sharedEvFFT = OSCSharedEvent.new(~localHost, "fft");

~caFFT = { |initCaSize = 8, initLastValuesSize = 10, startRules = 30|
	var win, game, gameBlockSize = 40;
	var newCaSize, newLastValuesSize;

	~sharedEvFFT.caSize = initCaSize;
	~sharedEvFFT.lastValuesSize = initLastValuesSize;
	~sharedEvFFT.currentRule = startRules;
	~sharedEvFFT.sendRate = 2;
	~sharedEvFFT.blendSteps = 10;
	~sharedEvFFT.makeOSCdefsForKeys;
	~sharedEvFFT.sendAll;

	win = Window.new(bounds: (initCaSize * gameBlockSize)@((initLastValuesSize + 1) * gameBlockSize)).front;
	win.view.background_(Color.black);
	win.drawFunc = {
		var cols = ~sharedEvFFT.caSize, rows = ~sharedEvFFT.lastValuesSize;
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

		Pen.addRect(Rect(game.relevantCa[1] * gameBlockSize,0, (~sharedEvFFT.caSize - game.relevantCa[1]) * gameBlockSize, rows * gameBlockSize));
		Pen.fillAxialGradient(Point(game.relevantCa[1] * gameBlockSize, 0), Point(~sharedEvFFT.caSize * gameBlockSize, 0), Color.gray(0, 0.333), Color.gray(0, 1));
	};

	game = (
		lastValues: (0 ! initCaSize) ! initLastValuesSize,
		saveLastValuesSize: initLastValuesSize,
		myGen: (0!initCaSize).put((initCaSize * 0.5).round, 1),
		seedMe: { |self| self.myGen = (0!~sharedEvFFT.caSize).put((~sharedEvFFT.caSize * 0.5).round, 1)},
		resizeWindow: { |self|
			win.bounds_(
				Rect(
					win.bounds.left,
					win.bounds.top,
					~sharedEvFFT.caSize * gameBlockSize,
					(~sharedEvFFT.lastValuesSize + 1) * gameBlockSize
				)
			)
		},
		// diese beiden funktionen muessen ohne self auskommen damit die connected werden koennen zum sharedEv
		newCaSize: { |newSize = 8|
			~sharedEvFFT.caSize = newSize;
			game.lastValues = (0 ! ~sharedEvFFT.caSize) ! ~sharedEvFFT.lastValuesSize; // was war kopieren?
			game.myGen = 0 ! ~sharedEvFFT.caSize; // das vorhandene kopieren ..
			game.seedMe;
			game.sumColums; // das ist wahrscheinlich notwendig?
			game.onlyShow(game.relevantSize);
			// resize window ..
			game.resizeWindow
		},
		newLastValuesSize: { |newSize = 10|
			if(newSize != game.saveLastValuesSize){
				[newSize, game.saveLastValuesSize].postln;
				if(newSize < game.saveLastValuesSize){
					game.lastValues = game.lastValues[..(newSize - 1)]
				}{
					game.lastValues = game.lastValues[..(newSize - 1)] ++ (
						(0 ! ~sharedEvFFT.caSize) ! (newSize - game.saveLastValuesSize)
					)
				};
				game.saveLastValuesSize = newSize;
				~sharedEvFFT.lastValuesSize = newSize;
				game.sumColums;
				// resize window ..
				game.resizeWindow
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
				col.sum / ~sharedEvFFT.lastValuesSize
			}
		},
		visualize: { |self|
			{win.refresh}.fork(AppClock)
		},
		makeRules: { |num|
			var arr = num.asBinaryDigits.reverse;
			("rule " ++ num).postln;
			~sharedEvFFT.currentRule = num;
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
		onlyShow: { |self, howMany|
			var caMid = (~sharedEvFFT.caSize / 2).asInteger;
			var start = caMid - (howMany / 2).asInteger;
			var end = start + howMany;
			self.relevantSize = howMany;
			self.relevantCa = [start, end]
		}
	);

	game.onlyShow(6);
	game[\makeRules].(startRules);

	~updateCaSizeFFT = ~sharedEvFFT.connectTo(game[\newCaSize])
	.filter({ |object, what, value| what == \caSize })
	.transform({ |object, what, value| [object.caSize, what, value].postln });
	OSCdef(\updateCaSizeFFT, {
		{~sharedEvFFT.changed(\caSize)}.defer(0.1)
	}, '/fft/caSize').fix;

	~updateLastValuesSizeFFT = ~sharedEvFFT.connectTo(game[\newLastValuesSize])
	.filter({ |object, what, value| what == \lastValuesSize })
	.transform({ |object, what, value| [object.lastValuesSize, what, value].postln });
	OSCdef(\updateLastValuesSizeFFT, {
		{~sharedEvFFT.changed(\lastValuesSize)}.defer(0.1)
	}, '/fft/lastValuesSize').fix;

	~updateCurrentRule = ~sharedEvFFT.connectTo(game[\makeRules])
	.filter({ |object, what, value| what == \currentRule })
	.transform({ |object, what, value| [object.currentRule, what, value].postln });
	OSCdef(\updateCurrentRuleFFT, {
		{~sharedEvFFT.changed(\currentRule)}.defer(0.1)
	}, '/fft/currentRule').fix;

	game
};


Tdef(\fftBinsGainSmooth, {
	var lastColSums = 0 ! ~sharedEvFFT.caSize;
	var nextColSums;
	var sendDb;
	var dbArr = [
		[-15, 12],
		[-15, 15],
		[-21, 21],
		[-27, 21],
		[-36, 21],
		[-9, 36]
	];
	var emphasizeMidSection = Env.new([0,0.5,1],[0.5,0.5],[5, -5]);
	loop {
		var blendSteps = ~sharedEvFFT.blendSteps;
		var sendRate = ~sharedEvFFT.sendRate; // Hz
		if(~sharedEvFFT.blendSteps > 1){
			var waitTime = (~sharedEvFFT.sendRate * blendSteps).reciprocal;
			~gameFFT.nextGen(false);
			nextColSums = ~gameFFT.colSums;
			blendSteps.do { |step|
				var blendedColSums = lastColSums.blend(nextColSums, step / blendSteps);
				~gameFFT.colSums = blendedColSums;
				~gameFFT.visualize; //~game.visualize(false);
				sendDb = ~gameFFT.colSums[3..8].collect {|v, ix|
					v = emphasizeMidSection[v];
					v.linlin(0, 1, dbArr[ix][0], dbArr[ix][1])
				};
				// sendDb = ~gameFFT.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, dbArr[ix][0], dbArr[ix][1], -4)};
				~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
				waitTime.wait;
			};
			lastColSums = nextColSums;
		}{
			~gameFFT.nextGen;
			sendDb = ~gameFFT.colSums[3..8].collect {|v, ix|
				v = emphasizeMidSection[v];
				v.linlin(0, 1, dbArr[ix][0], dbArr[ix][1])
			};
			// sendDb = ~gameFFT.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, dbArr[ix][0], dbArr[ix][1], -4)};
			~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
			sendRate.reciprocal.wait;
		}
	}
})