~ca = { |initCaSize = 8, initLastValuesSize = 10, startRules = 30|
	var win, game, gameBlockSize = 40;
	win = Window.new(bounds: (initCaSize * gameBlockSize)@((initLastValuesSize + 1) * gameBlockSize)).front;
	win.view.background_(Color.black);
	win.drawFunc = {
		var cols = game.caSize, rows = game.lastValuesSize;
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

		Pen.addRect(Rect(game.relevantCa[1] * gameBlockSize,0, (game.caSize - game.relevantCa[1]) * gameBlockSize, rows * gameBlockSize));
		Pen.fillAxialGradient(Point(game.relevantCa[1] * gameBlockSize, 0), Point(game.caSize * gameBlockSize, 0), Color.gray(0, 0.333), Color.gray(0, 1));
	};

	game = (
		caSize: initCaSize,
		lastValuesSize: initLastValuesSize,
		lastValues: (0 ! initCaSize) ! initLastValuesSize,
		myGen: (0!initCaSize).put((initCaSize * 0.5).round, 1),
		seedMe: { |self| self.myGen = (0!self.caSize).put((self.caSize * 0.5).round, 1)},
		resizeWindow: { |self|
			win.bounds_(
				Rect(
					win.bounds.left,
					win.bounds.top,
					self.caSize * gameBlockSize,
					(self.lastValuesSize + 1) * gameBlockSize
				)
			)
		},
		newCaSize: { |self, newSize = 8|
			self.caSize = newSize;
			self.lastValues = (0 ! self.caSize) ! self.lastValuesSize; // was war kopieren?
			self.myGen = 0 ! self.caSize; // das vorhandene kopieren ..
			self.seedMe;
			self.sumColums; // das ist wahrscheinlich notwendig?
			self.onlyShow(self.relevantSize);
			// resize window ..
			self.resizeWindow
		},
		newLastValuesSize: { |self, newSize = 10|
			if(newSize != self.lastValuesSize){
				if(newSize < self.lastValuesSize){
					self.lastValues = self.lastValues[..(newSize - 1)]
				}{
					self.lastValues = self.lastValues[..(newSize - 1)] ++ (
						(0 ! self.caSize) ! (newSize - self.lastValuesSize)
					)
				};
				//self.lastValues = (0 ! self.caSize) ! self.lastValuesSize;
				self.lastValuesSize = newSize;
				self.sumColums;
				// resize window ..
				self.resizeWindow
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
				col.sum / self.lastValuesSize
			}
		},
		visualize: { |self|
			{win.refresh}.fork(AppClock)
		},
		makeRules: { |self, num|
			var arr = num.asBinaryDigits.reverse;
			("rule " ++ num).postln;
			self.rules = (
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
			var caMid = (self.caSize / 2).asInteger;
			var start = caMid - (howMany / 2).asInteger;
			var end = start + howMany;
			self.relevantSize = howMany;
			self.relevantCa = [start, end]
		}
	);
	game.onlyShow(6);
	game.makeRules(startRules);
	game
};