// bei neuen onsets vom circle sequencer den ca sequencer weiterschalten
// der liefert dann werte fuer die dingers

// beim ca die letzten ... dings summieren um abstufungen zu kriegen

~makeRules = { |num|
	var arr = num.asBinaryDigits.reverse;
	("rule " ++ num).postln;
	~rules = (
		'000': arr[0],
		'001': arr[1],
		'010': arr[2],
		'011': arr[3],
		'100': arr[4],
		'101': arr[5],
		'110': arr[6],
		'111': arr[7]
	)
};

~makeRules.(86);
~makeRules.(131);
~makeRules.(6);
~makeRules.(9);
~makeRules.(30);
~makeRules.(121);

// to do

// evtl noch:
// beim sound die parameter pitches ... modulierbar?


~ca = { |initCaSize = 8, initLastValuesSize = 10|
	var win, game, gameBlockSize = 40;
	win = Window.new(bounds: (initCaSize * gameBlockSize)@((initLastValuesSize + 1) * gameBlockSize)).front;
	win.view.background_(Color.white);
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
			Pen.color = Color.gray(val);
			Pen.addRect(
				Rect(col * gameBlockSize, rows * gameBlockSize, gameBlockSize, gameBlockSize)
			);
			Pen.fill;
		}
	};

	// statt text Rect benutzen!
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
		nextGen: { |self|
			self.myGen = self.myGen.collect { |val index|
				var left = self.myGen.wrapAt(index - 1),
				right = self.myGen.wrapAt(index + 1);
				~rules[
					[left,val,right].reduce{|a b| a.asString ++ b.asString}.asSymbol
				];
			};
			self.lastValues = self.lastValues.shift(1, self.myGen);
			self.visualize;
			0
		},
		sumColumns: { |self|
			self.colSums = self.lastValues.flop.collect {|col|
				col.sum / self.lastValuesSize
			}
		},
		visualize: { |self|
			{
				self.sumColumns;
				win.refresh;
			}.fork(AppClock)
		}
	);
	game
};

~game = ~ca.(8, 10);
// ~game.myGen = (0!8).put(4, 1);
~game.newCaSize(12)
~game.newLastValuesSize(24)
~game.lastValues
~game = ~ca.(11, 21);

~game = ~ca.(12, 6); // mit rule 30 nette abwechslung
// ~game.myGen = (0!11).put(6, 1);
~game.nextGen
// sonify
{
	var taktDur = 1.2;
	var dbRange = -2 * 21;
	var dbCalc1 = { |colSums|
		var dbs = colSums.linlin(0, 1, dbRange, 0);
		dbs = dbs.collect {|val| if(val <= dbRange){-90}{val}};
		dbs
	};
	var dbCalc2 = { |colSums|
		var dbs = colSums.normalize.linlin(0, 1, dbRange, 0);
		dbs = dbs.collect {|val| if(val <= dbRange){-90}{val}};
		dbs
	};
	var dbCalc3 = { |colSums|
		var dbs = colSums.linlin(0, 1, dbRange, 0);
		var minDb = dbs.minItem;
		dbs = dbs.collect {|val| if(val <= minDb){-90}{val}};
		dbs
	};
	inf.do {
		var dbs;
		~game.nextGen;
		0.1.wait;
		dbs = dbCalc3.(~game.colSums);
		// Pbind(\dur, Pn(taktDur / 11), \db, Pseq(dbs).trace,\degree, Pseq([1,0,-1,0],inf),\legato, 0.1).play;
		// Pbind(\dur, Pn(taktDur / 11), \db, Pseq(dbs).trace,\degree, Pseq([1,0,-1,0,-2],inf),\legato, 0.1).play;
		Pbind(\dur, Pn(taktDur / 12), \db, Pseq(dbs).trace,\degree, Pseq([1,0,-1,0],inf),\legato, 0.1).play;
		(taktDur - 0.1).wait;
	}
}.fork

s.record
~game.colSums.normalize