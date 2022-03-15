~newCaRhythm = { |ev, prefix|
	// functions and network
	ev = ();
	ev.maxSize = 16;
	ev.toOSC = ~localHost;

	ev.sharedEv = OSCSharedEvent.new(~localHost, prefix);
	ev.sharedEv.caSize = 16;
	ev.sharedEv.linkFFTCa = 0;
	ev.sharedEv.linkBitFlip = 0;
	ev.sharedEv.onOff = 0;

	ev.makeLinkToFFTCa = {|onOff|
		ev.pbindChain = if(onOff.asBoolean){
			Pbind(\callFunc, Pfunc{|ev| if(ev.amp > 0){Pdefn(\caFFTNext).asStream.next};0})
		}{
			Pbind()
		};
		ev.sharedEv.linkFFTCa = onOff; // falls man es manuell aendert aenderung zu osc schickens
	};
	ev.makeLinkToBitFlip = {|onOff|
		ev.pbindChain = if(onOff.asBoolean){
			Pbind(\callFunc, Pfunc{|ev| if(ev.amp > 0){Pdefn(\bitflipNext).asStream.next};0})
		}{
			Pbind()
		};
		ev.sharedEv.linkBitFlip = onOff;
	};

	ev.buttonStates = 0 ! ev.maxSize;
	ev.maxSize.do { |i|
		OSCdef((prefix ++ 'button' ++ i).asSymbol, { |msg|
			ev.buttonStates[i] = msg[1].asInteger;
		},"/" +/+ prefix +/+ "buttons/" ++ i).fix
	};
	ev.makeRules = { |num|
		var arr = num.asBinaryDigits.reverse;
		("rule " ++ num).postln;
		ev.rules = (
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

	ev.ca = {
		(
			myGen: 0 ! ev.sharedEv.caSize,
			nextGen: { |self|
				self.myGen = (self.myGen + ev.buttonStates[..(ev.sharedEv.caSize - 1)]).clip(0,1);
				self.myGen = self.myGen.collect { |val index|
					var left = self.myGen.wrapAt(index - 1),
					right = self.myGen.wrapAt(index + 1);
					ev.rules[
						[left,val,right].reduce{|a b| a.asString ++ b.asString}.asSymbol
					];
				};
			}
		)
	};

	ev.changeSize = { |newSize|
		var oldSize = ev.sharedEv.caSize;
		if(newSize > ev.sharedEv.caSize){
			var addZeroes = 0 ! (newSize - ev.sharedEv.caSize);
			ev.sharedEv.caSize = newSize;
			(ev.nextLevel ++ [ev.gen]).do {|ca|
				ca !? {
					ca.myGen = ca.myGen ++ addZeroes;
				}
			}
		}{
			(ev.nextLevel ++ [ev.gen]).do {|ca|
				ca !? {
					ca.myGen = ca.myGen[..(newSize - 1)];
				}
			};
			(newSize .. (ev.nextLevel.size - 1)).do {|i|
				ev.nextLevel[i] = nil;
			};
			ev.sharedEv.caSize = newSize;
			{ev.resizeWin}.defer;
		};
	};

	ev.resizeWin = {
		ev.win.bounds_(
			Rect(
				ev.win.bounds.left,
				ev.win.bounds.top,
				ev.sharedEv.caSize * ev.gameBlockCol,
				ev.sharedEv.caSize * ev.gameBlockRow
			)
		)
	};

	ev[\makeRules].(86);

	ev.sharedEv.currentRule = 86;

	ev.sharedEv.makeOSCdefsForKeys((
		currentRule: ev[\makeRules],
		caSize: ev[\changeSize],
		linkFFTCa: ev[\makeLinkToFFTCa],
		linkBitFlip: ev[\makeLinkToBitFlip],
		onOff: {|onOff|
			if(onOff.asBoolean){
				Pdef((prefix ++ "spawner").asSymbol).play(quant: 1)
			}{
				Pdef((prefix ++ "spawner").asSymbol).stop
			};
			ev.sharedEv.onOff = onOff;
		}
	));
	ev.sharedEv.sendAll;


	// gui
	ev.gameBlockSize = 40;
	ev.gameBlockRow = 40 / 1.61803398875;
	ev.gameBlockCol = 40;
	ev.win = Window.new(prefix, bounds:(ev.maxSize * ev.gameBlockCol)@(ev.maxSize * ev.gameBlockRow)).front;
	ev.view = UserView.new(ev.win, (ev.maxSize * ev.gameBlockCol)@(ev.maxSize * ev.gameBlockRow));
	ev.view.background_(Color.black);
	ev.view.clearOnRefresh = false;
	ev.drawIndex = 0;
	ev.hitColor = \red;
	ev.view.drawFunc = {
		// ev.drawIndex.postln;
		if(ev.drawIndex == 0){
			//
			ev.nextLevel.do { |ca, row|
				if(ca.notNil){
					ca.mixedGen.do {|val, col|
						if(col == 0){
							Pen.color = Color.perform(ev.hitColor, val);
						}{
							Pen.color = Color.gray(0.5 * val);
						};
						Pen.addRect(
							Rect(col * ev.gameBlockCol, row * ev.gameBlockRow, ev.gameBlockCol, ev.gameBlockRow)
						);
						Pen.fill;
					};
				}
			};
		}{
			ev.nextLevel.do { |ca, row|
				if(ca.notNil){
					ca.mixedGen.do {|val, col|
						if(col == ev.drawIndex){
							Pen.color = Color.perform(ev.hitColor, val);
							Pen.addRect(
								Rect(col * ev.gameBlockCol, row * ev.gameBlockRow, ev.gameBlockCol, ev.gameBlockRow)
							);
							Pen.fill;
						}
					};
				}
			};
			if(ev.drawIndex == (ev.sharedEv.caSize - 1)){
				ev.view.clearDrawing;
			}
		}
	};

	// game spawner
	ev.gen = ev[\ca].();
	ev.nextLevel = nil!(ev.maxSize + 1);
	// structure pbind, next event at each step
	ev.evPat = Pbind(
		\loopOnOff, true,
		\pulseSpeed, Pseq([1/8],inf),
		\steps, 4,
		\chan, 13,
		\midinote, 36
	).asStream;
	ev.pbindChain = Pbind();
	ev.spawner = Pspawner({ |sp|
		var stepEv = ev.evPat.next(());
		var loopPbind;
		var accumGens = [0];
		inf.do {
			var loop, loopGen = false;
			stepEv.steps.do { |step|
				loop = stepEv.loopOnOff and: {loopPbind.notNil and: {accumGens.sum > 0}};
				// "loopGen: ".post; loopGen.postln;
				if(loop){
					"looping".postln;
					sp.par(loopPbind);
					ev.sharedEv.caSize.do { |i|
						{
							ev.drawIndex = i;
							ev.view.refresh
						}.fork(AppClock);
						sp.wait(stepEv.pulseSpeed);
					};
				}{
					var durTime;
					loopGen = true;
					accumGens = [0];
					durTime = stepEv.pulseSpeed;
					" notlooping".postln;
					ev.gen.myGen.do { |val, ix|
						if(val.asBoolean){
							var mixedGen, mixedGenPbind;
							if(ev.lastGen.notNil){
								// wenn zuvor 0 war
								if((ev.lastGen[ix].asBoolean.not and:{step == 0}) or:
									{ev.nextLevel[ix].isNil}){
									ev.nextLevel[ix] = ev[\ca].();
								}{// falls zuvor schon 1 war
									ev.nextLevel[ix].nextGen;
								};
							}{
								if((step == 0) or: {ev.nextLevel[ix].isNil}){
									ev.nextLevel[ix] = ev[\ca].();
								}{
									ev.nextLevel[ix].nextGen;
								};
							};
							mixedGen = ev.nextLevel[ix].myGen * ev.gen.myGen;
							ev.nextLevel[ix].mixedGen = mixedGen;
							accumGens = accumGens + mixedGen;
						}{
							ev.nextLevel[ix] = nil;
						};
					};
					//accumGens.postln;
					if(accumGens.size > 1){
						loopPbind = ev.pbindChain <> Pbind(
							\dur, stepEv.pulseSpeed,
							\instrument, \no,
							\type, \oscMidi,
							\amp, Pseq(accumGens / ev.sharedEv.caSize),
							\chan, stepEv.chan,
							\midinote, stepEv.midinote,
							\netAddr, ~toBenni
						);
						sp.par(loopPbind);
					};
					//visualize
					ev.sharedEv.caSize.do { |i|
						{
							ev.drawIndex = i;
							ev.view.refresh
						}.fork(AppClock);
						sp.wait(stepEv.pulseSpeed);
					};
				};
				//
				// sp.wait(stepEv.pulseSpeed * ev.sharedEv.caSize);
				stepEv = ev.evPat.next(());
			};

			if(loopGen){
				"new gen".postln;
				ev.lastGen = ev.gen.myGen;
				ev.gen.nextGen;
			}{
				"NO new gen".postln;
			};
		};
	});
	Pdef((prefix ++ "spawner").asSymbol, ev.spawner);

	ev
};


