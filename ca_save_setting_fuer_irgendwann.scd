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
~makeRules.(12);


~ca = { |caSize = 8, lastValuesSize = 10|
	var win, buttons, texts, game;
	win = Window.new(bounds: (caSize * 45 + 20)@(50 * lastValuesSize + 30)).front;
	win.view.decorator = FlowLayout(win.view.bounds, 10@10, 5@5 );
	buttons = (caSize * lastValuesSize).collect{ Button(win.view,40@40 ).states_([
		["", Color.white, Color.white],
		["", Color.grey(0, 1 / lastValuesSize), Color.grey(0, 1 / lastValuesSize)]
	])}.clump(caSize);
	texts = caSize.collect {StaticText(win.view,40@40 ).background = Color.white};
	game = (
		lastValues: (0 ! caSize) ! lastValuesSize,
		myGen: 0 ! caSize,
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
			self.colSums = self.lastValues.flop.collect {|col| col.sum / lastValuesSize}
		},
		visualize: { |self|
			{
				// visualize all last values
				self.lastValues.do {|vals, ix|
					vals.do{ |onOff, pos| buttons[ix][pos].value = onOff}
				};
				// calc sum and show
				self.sumColumns;
				self.colSums.do {|val, ix|
					texts[ix].background = Color.grey(0, val)
				}
			}.fork(AppClock)
		}
	);
	game
};

~game = ~ca.(8, 5);
~game.myGen = [0, 0, 0, 1, 0, 0, 0, 0];
~game.nextGen
// sonify
{
	var taktDur = 2/3;
	inf.do {
		var dbs;
		~game.nextGen;
		0.1.wait;
		dbs = ~game.colSums.linlin(0, 1, -3 * 7, 0); // hier mit lastValue size mult

		// dbs = ~game.colSums.normalize.linlin(0, 1, -15, 0);
		dbs = dbs.collect {|val| if(val <= (-3 * 7)){-90}{val}};
		Pbind(\dur, Pn(taktDur / 8), \db, Pseq(dbs).trace,\degree, Pseq([1,0,-1,0],inf),\legato, 0.1).play;
		(taktDur - 0.1).wait;
	}
}.fork

s.record
~game.colSums.normalize