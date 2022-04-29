~caFFT = { |initCaSize = 8, initLastValuesSize = 10, startRules = 30, frontWindow = (false)|
	var win, game, gameBlockSize = 30;
	var newCaSize, newLastValuesSize;
	var prefix = "fft";
	var sharedEvFFT = OSCSharedEvent.new(~localHost, prefix);

	sharedEvFFT.caSize = initCaSize;
	sharedEvFFT.lastValuesSize = initLastValuesSize;
	sharedEvFFT.currentRule = startRules;
	sharedEvFFT.sendRate = 2;
	sharedEvFFT.blendSteps = 10;
	sharedEvFFT.caRange = [0, 5];
	sharedEvFFT.tdefOnOff = 0;
	sharedEvFFT.blockOrPass = 0;
	sharedEvFFT.fftDepth = 1;

	win = Window.new(prefix, bounds: (initCaSize * gameBlockSize)@((initLastValuesSize + 1) * gameBlockSize), resizable: false, border: ~guiBorder);
	//.autoRememberPosition(\bitrot, prefix.asSymbol);
	if(frontWindow){
		win.front
	};
	win.view.background_(~guiBackgroundColor);
	win.drawFunc = {
		var cols = sharedEvFFT.caSize, rows = sharedEvFFT.lastValuesSize;
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

		Pen.addRect(Rect(game.relevantCa[1] * gameBlockSize,0, (sharedEvFFT.caSize - game.relevantCa[1]) * gameBlockSize, rows * gameBlockSize));
		Pen.fillAxialGradient(Point(game.relevantCa[1] * gameBlockSize, 0), Point(sharedEvFFT.caSize * gameBlockSize, 0), Color.gray(0, 0.333), Color.gray(0, 1));
	};

	game = (
		setOfVisible: Set.new(),
		windowOnOff: { |onOff, sym|
			if(onOff){
				game.setOfVisible.add(sym);
				{win.visible_(true)}.defer
			}{
				game.setOfVisible.remove(sym);
				if(game.setOfVisible.isEmpty){{win.visible_(false)}.defer}
			}
		},
		pointerToWindow: win,
		sharedEv: sharedEvFFT,
		lastValues: (0 ! initCaSize) ! initLastValuesSize,
		saveLastValuesSize: initLastValuesSize,
		myGen: (0!initCaSize).put((initCaSize * 0.5).round, 1),
		seedMe: { |self| self.myGen = (0!sharedEvFFT.caSize).put((sharedEvFFT.caSize * 0.5).round, 1)},
		killSwitch: { |self| self.myGen = (0!sharedEvFFT.caSize)},
		resizeWindow: { |self|
			if(win.isClosed.not){
				win.bounds_(
					Rect(
						win.bounds.left,
						win.bounds.top,
						sharedEvFFT.caSize * gameBlockSize,
						(sharedEvFFT.lastValuesSize + 1) * gameBlockSize
					)
				)
			}
		},
		// diese beiden funktionen muessen ohne self auskommen damit die connected werden koennen zum sharedEv
		newCaSize: { |newSize = 8|
			// sharedEvFFT.caSize = newSize;
			game.lastValues = (0 ! newSize) ! sharedEvFFT.lastValuesSize; // was war kopieren?
			game.myGen = 0 ! newSize; // das vorhandene kopieren ..
			game.seedMe;
			game.sumColums; // das ist wahrscheinlich notwendig?
			game[\onlyShow].(sharedEvFFT.caRange);
			// resize window ..
			{game.resizeWindow}.defer(0.1);
		},
		newLastValuesSize: { |newSize = 10|
			// koennte sharedEvFFT.lastValuesSize statt game.saveLastValuesSize nutzen
			if(newSize != game.saveLastValuesSize){
				// [newSize, game.saveLastValuesSize].postln;
				if(newSize < game.saveLastValuesSize){
					game.lastValues = game.lastValues[..(newSize - 1)]
				}{
					game.lastValues = game.lastValues[..(newSize - 1)] ++ (
						(0 ! sharedEvFFT.caSize) ! (newSize - game.saveLastValuesSize)
					)
				};
				game.saveLastValuesSize = newSize;
				// sharedEvFFT.lastValuesSize = newSize;
				game.sumColums;
				// resize window ..
				{game.resizeWindow}.defer(0.1);
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
				col.sum / sharedEvFFT.lastValuesSize
			}
		},
		visualize: { |self|
			{win.refresh}.fork(AppClock)
		},
		makeRules: { |num|
			var arr = num.asBinaryDigits.reverse;
			// ("rule " ++ num).postln;
			//sharedEvFFT.currentRule = num;
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
			var caMid = (sharedEvFFT.caSize / 2).asInteger;
			var relevantSize = range[1] - range[0] + 1;
			var start = caMid - 3 + range[0]; //(relevantSize / 2).asInteger;
			var end = start + relevantSize;
			game.delayedCaRange = range; // necessary for Tdef
			game.relevantCa = [start, end]
		}
	);

	game[\onlyShow].(sharedEvFFT.caRange);
	game[\makeRules].(startRules);

	sharedEvFFT.makeOSCdefsForKeys((
		caSize: game[\newCaSize],
		lastValuesSize: game[\newLastValuesSize],
		currentRule: game[\makeRules],
		caRange: game[\onlyShow],
		tdefOnOff: {|onOff|
			game[\windowOnOff].(onOff.asBoolean, prefix.asSymbol);
			if(onOff.asBoolean){
				Tdef(\fftBinsGainSmooth).play(quant: 1);
				~game1.sharedEv.linkFFTCa = 0;
				~game2.sharedEv.linkFFTCa = 0;
				~clipSequencer.sharedEv.linkFFTCa = 0;
				// game[\windowOnOff].(onOff.asBoolean, prefix.asSymbol);
				//{win.visible_(true)}.defer
			}{
				Tdef(\fftBinsGainSmooth).stop;
				// {win.visible_(false)}.defer
			};

			//sharedEvFFT.tdefOnOff = onOff;
		},
		sendRate: {
			Tdef(\fftBinsGainSmooth).quant_(1);
			Tdef(\fftBinsGainSmooth, game[\tdefLoopFunc]);
		}
	));
	sharedEvFFT.sendAll;

	// seedMe and killswitch OSCdefs
	OSCdef((prefix ++ 'seedMe').asSymbol, { |msg|
		if(msg[1].asBoolean){game.seedMe}
	},"/" +/+ prefix +/+ "seedMe").fix;

	OSCdef((prefix ++ 'killSwitch').asSymbol, { |msg|
		if(msg[1].asBoolean){game.killSwitch}
	},"/" +/+ prefix +/+ "killSwitch").fix;

	// send 0 dB for all bands
	OSCdef((prefix ++ 'set_0_dB').asSymbol, { |msg|
		~toBenni.sendMsg("/bitrotData", "fftBinsGain", *[0, 0, 0, 0, 0, 0]);
	},"/" +/+ prefix +/+ "set_0_dB").fix;

	game.presetManager = ~makePresetManager.(prefix,["~gameFFT.sharedEv"]);

	game.tdefLoopFunc = {
		var lastColSums = 0 ! game.sharedEv.caSize;
		var nextColSums;
		var sendDb;
		var sendDbDummyAllOn = 0!6;//-60!6;
		var sendDbDummyAllOff = -60!6;
		var dbArr = [
			[-70, 0],
			[-70, 0],
			[-70, 0],
			[-70, 0],
			[-70, 0],
			[-70, 0]
		];
		var emphasizeMidSection = Env.new([0,0.5,1],[0.5,0.5],[3, -3]);
		var calcDbArray = {
			var res = if(game.sharedEv.blockOrPass.asBoolean){sendDbDummyAllOn.copy}{sendDbDummyAllOff.copy};
			game.colSums[game.relevantCa[0]..(game.relevantCa[1] - 1)].do {|v, ix|
				res[ix + game.delayedCaRange[0]] = emphasizeMidSection[v].linlin(
					0, 1, *(dbArr[ix] * game.sharedEv.fftDepth)
				)
			};
			res
		};
		var sendRate = game.sharedEv.sendRate; // nur auf quantisierung neu
		loop {
			var blendSteps = game.sharedEv.blendSteps;
			if(blendSteps > 1){
				var waitTime = (sendRate * blendSteps).reciprocal;
				game.nextGen(false);
				nextColSums = game.colSums;
				blendSteps.do { |step|
					var blendedColSums = lastColSums.blend(nextColSums, step / blendSteps);
					game.colSums = blendedColSums;
					game.visualize;
					sendDb = calcDbArray.();
					~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
					waitTime.wait;
				};
				lastColSums = nextColSums;
			}{
				game.nextGen;
				sendDb = calcDbArray.();
				~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
				sendRate.reciprocal.wait;
			};
		}
	};
	Tdef(\fftBinsGainSmooth, game[\tdefLoopFunc]);

	game
};



Pdefn(\caFFTNext, Routine {
	var lastColSums = 0 ! ~gameFFT.sharedEv.caSize;
	var nextColSums;
	var sendDb;
	var sendDbDummyAllOn = 0!6;//-60!6;
	var sendDbDummyAllOff = -60!6;
	var dbArr = [
		[-70, 0],
		[-70, 0],
		[-70, 0],
		[-70, 0],
		[-70, 0],
		[-70, 0]
	];
	/*	var dbArr = [
	[-15, 1],
	[-9, 1],
	[-21, 1],
	[-27, 1],
	[-36, 1],
	[-9, 1]
	];*/
	var emphasizeMidSection = Env.new([0,0.5,1],[0.5,0.5],[5, -5]);
	var calcDbArray = {
		var res = if(~gameFFT.sharedEv.blockOrPass.asBoolean){sendDbDummyAllOn.copy}{sendDbDummyAllOff.copy};
		~gameFFT.colSums[~gameFFT.relevantCa[0]..(~gameFFT.relevantCa[1] - 1)].do {|v, ix|
			res[ix + ~gameFFT.delayedCaRange[0]] = emphasizeMidSection[v].linlin(
				0, 1, *(dbArr[ix] * ~gameFFT.sharedEv.fftDepth)
			)
		};
		res
	};
	//var colorPseq = Pwrand([Color.white, Color.red],[0.8,0.2],inf).asStream;
	loop {
		//{~scopeGUI.options.penColor = colorPseq.next}.defer;
		// var blendSteps = ~gameFFT.sharedEv.blendSteps;
		~gameFFT.nextGen;
		sendDb = calcDbArray.();
		~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
		1.yield;
	}
});
