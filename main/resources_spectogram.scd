
~spectograms = (big: (), small: ());

~spectograms.big.win = Window.new("specBig", Rect(1920,0, 1920, 480),border:~guiBorder)
.background_(~guiBackgroundColor).autoRememberPosition(\bitrot, \spectrogramBig);
~spectograms.big.spectogram = Spectrogram.new(~spectograms.big.win, Rect(0,0, 1920, 480), inbus: ~guiInputBus).background_(~guiBackgroundColor);
~spectograms.big.spectogram.intensity = 200;
~spectograms.big.spectogram.rate = 20; // frameRate in hz
~spectograms.big.onOffState = false; // keine doppelten runs und stops zulassen
~spectograms.big.onOff = { |onOff|
	onOff = onOff.asBoolean;
	if(onOff){
		if(~spectograms.big.onOffState.not){
			~spectograms.big.spectogram.start;
			{~spectograms.big.win.visible_(onOff)}.defer;
			~spectograms.big.onOffState = onOff
		}
	}{
		if(~spectograms.big.onOffState){
			~spectograms.big.spectogram.stop;
			{~spectograms.big.win.visible_(onOff)}.defer;
			~spectograms.big.onOffState = onOff
		}
	};
};
~spectograms.big.win.visible_(false);

// klein und vertikal, scrolling
~spectograms.small.win = Window.new("specSmall", Rect(10,10, 300, 200),border:~guiBorder).background_(~guiBackgroundColor).autoRememberPosition(\bitrot, \spectrogramSmall);
~spectograms.small.spectogram = Spectrogram3.new(~spectograms.small.win, Rect(0, 0, 300, 200), inbus: ~guiInputBus).background_(~guiBackgroundColor);
~spectograms.small.spectogram.intensity = 105;
~spectograms.small.spectogram.rate = 20; // frameRate in hz
~spectograms.small.onOffState = false; // keine doppelten runs und stops zulassen
~spectograms.small.onOff = { |onOff|
	onOff = onOff.asBoolean;
	if(onOff){
		if(~spectograms.small.onOffState.not){
			~spectograms.small.spectogram.start;
			{~spectograms.small.win.visible_(onOff)}.defer;
			~spectograms.small.onOffState = onOff
		};
	}{
		if(~spectograms.small.onOffState){
			~spectograms.small.spectogram.stop;
			{~spectograms.small.win.visible_(onOff)}.defer;
			~spectograms.small.onOffState = onOff
		}
	};
};
~spectograms.small.win.visible_(false);

s.sync;