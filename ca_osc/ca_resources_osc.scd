thisProcess.openUDPPort(9010);
~sharedEv = OSCSharedEvent.new(NetAddr("127.0.0.1", 9001));

~ca = { |initCaSize = 8, initLastValuesSize = 10, startRules = 30|
	var win, game, gameBlockSize = 40;
	var newCaSize, newLastValuesSize;

	~sharedEv.caSize = initCaSize;
	~sharedEv.lastValuesSize = initLastValuesSize;
	~sharedEv.currentRule = startRules;
	~sharedEv.sendRate = 2;
	~sharedEv.blendSteps = 10;
	~sharedEv.makeOSCdefsForKeys;
	~sharedEv.sendAll;

	win = Window.new(bounds: (initCaSize * gameBlockSize)@((initLastValuesSize + 1) * gameBlockSize)).front;
	win.view.background_(Color.black);
	win.drawFunc = {
		var cols = ~sharedEv.caSize, rows = ~sharedEv.lastValuesSize;
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

		Pen.addRect(Rect(game.relevantCa[1] * gameBlockSize,0, (~sharedEv.caSize - game.relevantCa[1]) * gameBlockSize, rows * gameBlockSize));
		Pen.fillAxialGradient(Point(game.relevantCa[1] * gameBlockSize, 0), Point(~sharedEv.caSize * gameBlockSize, 0), Color.gray(0, 0.333), Color.gray(0, 1));
	};

	game = (
		lastValues: (0 ! initCaSize) ! initLastValuesSize,
		saveLastValuesSize: initLastValuesSize,
		myGen: (0!initCaSize).put((initCaSize * 0.5).round, 1),
		seedMe: { |self| self.myGen = (0!~sharedEv.caSize).put((~sharedEv.caSize * 0.5).round, 1)},
		resizeWindow: { |self|
			win.bounds_(
				Rect(
					win.bounds.left,
					win.bounds.top,
					~sharedEv.caSize * gameBlockSize,
					(~sharedEv.lastValuesSize + 1) * gameBlockSize
				)
			)
		},
		// diese beiden funktionen muessen ohne self auskommen damit die connected werden koennen zum sharedEv
		newCaSize: { |newSize = 8|
			~sharedEv.caSize = newSize;
			game.lastValues = (0 ! ~sharedEv.caSize) ! ~sharedEv.lastValuesSize; // was war kopieren?
			game.myGen = 0 ! ~sharedEv.caSize; // das vorhandene kopieren ..
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
						(0 ! ~sharedEv.caSize) ! (newSize - game.saveLastValuesSize)
					)
				};
				game.saveLastValuesSize = newSize;
				~sharedEv.lastValuesSize = newSize;
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
				col.sum / ~sharedEv.lastValuesSize
			}
		},
		visualize: { |self|
			{win.refresh}.fork(AppClock)
		},
		makeRules: { |num|
			var arr = num.asBinaryDigits.reverse;
			("rule " ++ num).postln;
			~sharedEv.currentRule = num;
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
			var caMid = (~sharedEv.caSize / 2).asInteger;
			var start = caMid - (howMany / 2).asInteger;
			var end = start + howMany;
			self.relevantSize = howMany;
			self.relevantCa = [start, end]
		}
	);

	game.onlyShow(6);
	game[\makeRules].(startRules);

	~updateCaSize = ~sharedEv.connectTo(game[\newCaSize])
	.filter({ |object, what, value| what == \caSize })
	.transform({ |object, what, value| [object.caSize, what, value].postln });
	OSCdef(\updateCaSize, {
		{~sharedEv.changed(\caSize)}.defer(0.1)
	}, '/caSize').fix;

	~updateLastValuesSize = ~sharedEv.connectTo(game[\newLastValuesSize])
	.filter({ |object, what, value| what == \lastValuesSize })
	.transform({ |object, what, value| [object.lastValuesSize, what, value].postln });
	OSCdef(\updateLastValuesSize, {
		{~sharedEv.changed(\lastValuesSize)}.defer(0.1)
	}, '/lastValuesSize').fix;

	~updateCurrentRule = ~sharedEv.connectTo(game[\makeRules])
	.filter({ |object, what, value| what == \currentRule })
	.transform({ |object, what, value| [object.currentRule, what, value].postln });
	OSCdef(\updateCurrentRule, {
		{~sharedEv.changed(\currentRule)}.defer(0.1)
	}, '/currentRule').fix;

	game
};