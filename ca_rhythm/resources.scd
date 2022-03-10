// functions and network
~caRhy = ();
~caRhy.maxSize = 16;
~caRhy.toOSC = NetAddr("127.0.0.1", 9001);
thisProcess.openUDPPort(9010);
~caRhy.sharedEv = OSCSharedEvent.new(NetAddr("127.0.0.1", 9001));
~caRhy.sharedEv.caSize = 16;
~caRhy.buttonStates = 0 ! ~caRhy.maxSize;
~caRhy.maxSize.do { |i|
	OSCdef(('button' ++ i).asSymbol, { |msg|
		~caRhy.buttonStates[i] = msg[1].asInteger;
	}, "/buttons/" ++ i).fix
};
~caRhy.makeRules = { |num|
	var arr = num.asBinaryDigits.reverse;
	("rule " ++ num).postln;
	~caRhy.rules = (
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

~caRhy.ca = {
	(
		myGen: 0 ! ~caRhy.sharedEv.caSize,
		nextGen: { |self|
			self.myGen = (self.myGen + ~caRhy.buttonStates[..(~caRhy.sharedEv.caSize - 1)]).clip(0,1);
			self.myGen = self.myGen.collect { |val index|
				var left = self.myGen.wrapAt(index - 1),
				right = self.myGen.wrapAt(index + 1);
				~caRhy.rules[
					[left,val,right].reduce{|a b| a.asString ++ b.asString}.asSymbol
				];
			};
		}
	)
};

~caRhy.changeSize = { |newSize|
	var oldSize = ~caRhy.sharedEv.caSize;
	if(newSize > ~caRhy.sharedEv.caSize){
		var addZeroes = 0 ! (newSize - ~caRhy.sharedEv.caSize);
		~caRhy.sharedEv.caSize = newSize;
		(~caRhy.nextLevel ++ [~caRhy.gen]).do {|ca|
			ca !? {
				ca.myGen = ca.myGen ++ addZeroes;
			}
		}
	}{
		(~caRhy.nextLevel ++ [~caRhy.gen]).do {|ca|
			ca !? {
				ca.myGen = ca.myGen[..(newSize - 1)];
			}
		};
		(newSize .. (~caRhy.nextLevel.size - 1)).do {|i|
			~caRhy.nextLevel[i] = nil;
		};
		~caRhy.sharedEv.caSize = newSize;
		{~caRhy.resizeWin}.defer;
	};
};

~caRhy.resizeWin = {
	~caRhy.win.bounds_(
		Rect(
			~caRhy.win.bounds.left,
			~caRhy.win.bounds.top,
			~caRhy.sharedEv.caSize * ~caRhy.gameBlockCol,
			~caRhy.sharedEv.caSize * ~caRhy.gameBlockRow
		)
	)
};

~caRhy[\makeRules].(86);

~caRhy.sharedEv.currentRule = 86;

~caRhy.sharedEv.makeOSCdefsForKeys;
~caRhy.updateRules = ~caRhy.sharedEv.connectTo(~caRhy[\makeRules])
.filter({ |object, what, value| what == \currentRule })
.transform({ |object, what, value| [object.currentRule, what, value].postln });
OSCdef(\updateCurrentRule, {
	{~caRhy.sharedEv.changed(\currentRule)}.defer(0.1)
}, '/currentRule').fix;

~caRhy.updateSize = ~caRhy.sharedEv.connectTo(~caRhy[\changeSize])
.filter({ |object, what, value| what == \caSize })
.transform({ |object, what, value| [object.caSize, what, value].postln });
OSCdef(\updateCaSize, {
	{~caRhy.sharedEv.changed(\caSize)}.defer(0.1)
}, '/caSize').fix;

// gui
~caRhy.gameBlockSize = 40;
~caRhy.gameBlockRow = 40 / 1.61803398875;
~caRhy.gameBlockCol = 40;
~caRhy.win = Window.new(bounds:(~caRhy.maxSize * ~caRhy.gameBlockCol)@(~caRhy.maxSize * ~caRhy.gameBlockRow)).front;
~caRhy.view = UserView.new(~caRhy.win, (~caRhy.maxSize * ~caRhy.gameBlockCol)@(~caRhy.maxSize * ~caRhy.gameBlockRow));
~caRhy.view.background_(Color.black);
~caRhy.view.clearOnRefresh = false;
~caRhy.drawIndex = 0;
~caRhy.view.drawFunc = {
	// ~caRhy.drawIndex.postln;
	if(~caRhy.drawIndex == 0){
		//
		~caRhy.nextLevel.do { |ca, row|
			if(ca.notNil){
				ca.mixedGen.do {|val, col|
					if(col == 0){
						Pen.color = Color.red(val);
					}{
						Pen.color = Color.gray(0.5 * val);
					};
					Pen.addRect(
						Rect(col * ~caRhy.gameBlockCol, row * ~caRhy.gameBlockRow, ~caRhy.gameBlockCol, ~caRhy.gameBlockRow)
					);
					Pen.fill;
				};
			}
		};
	}{
		~caRhy.nextLevel.do { |ca, row|
			if(ca.notNil){
				ca.mixedGen.do {|val, col|
					if(col == ~caRhy.drawIndex){
						Pen.color = Color.red(val);
						Pen.addRect(
							Rect(col * ~caRhy.gameBlockCol, row * ~caRhy.gameBlockRow, ~caRhy.gameBlockCol, ~caRhy.gameBlockRow)
						);
						Pen.fill;
					}
				};
			}
		};
		if(~caRhy.drawIndex == (~caRhy.sharedEv.caSize - 1)){
			~caRhy.view.clearDrawing;
		}
	}
};

// game spawner
~caRhy.gen = ~caRhy[\ca].();
~caRhy.nextLevel = nil!(~caRhy.maxSize + 1);
// structure pbind, next event at each step
~caRhy.evPat = Pbind(
	\degree, Pdup(2, Pseq([-4, 1, 3, 6].scramble - 7, inf)),
	\pulseSpeed, Pseq([1/8],inf),
	\steps, 4
).asStream;
~caRhy.spawner = Pspawner({ |sp|
	var stepEv = ~caRhy.evPat.next(());
	inf.do {
		stepEv.steps.do { |step|
			var durTime, accumGens = [0];
			durTime = stepEv.pulseSpeed;
			~caRhy.gen.myGen.do { |val, ix|
				if(val.asBoolean){
					var mixedGen, mixedGenPbind, countAndValArrays;
					if(~caRhy.lastGen.notNil){
						// wenn zuvor 0 war
						if(~caRhy.lastGen[ix].asBoolean.not and:{step == 0}){
							~caRhy.nextLevel[ix] = ~caRhy[\ca].();
						}{// falls zuvor schon 1 war
							~caRhy.nextLevel[ix].nextGen;
						};
					}{
						if(step == 0){
							~caRhy.nextLevel[ix] = ~caRhy[\ca].();
						}{
							~caRhy.nextLevel[ix].nextGen;
						};
					};
					mixedGen = ~caRhy.nextLevel[ix].myGen * ~caRhy.gen.myGen;
					~caRhy.nextLevel[ix].mixedGen = mixedGen;
					accumGens = accumGens + mixedGen;
				}{
					~caRhy.nextLevel[ix] = nil;
				};
			};
			//accumGens.postln;
			if(accumGens.size > 1){
				sp.par(
					Pbind(
						\dur, stepEv.pulseSpeed,
						\instrument, \no,
						\type, \oscMidi,
						\amp, Pseq(accumGens / ~caRhy.sharedEv.caSize),
						\chan, 13,
						\midinote,36,
						// \db, -50,
						\netAddr, ~toBenni
					)
				);
			};
			//visualize
			~caRhy.sharedEv.caSize.do { |i|
				{
					~caRhy.drawIndex = i;
					~caRhy.view.refresh
				}.fork(AppClock);
				sp.wait(stepEv.pulseSpeed);
			};
			//
			// sp.wait(stepEv.pulseSpeed * ~caRhy.sharedEv.caSize);
			stepEv = ~caRhy.evPat.next(());
		};

		~caRhy.lastGen = ~caRhy.gen.myGen;
		~caRhy.gen.nextGen;
	};
});




