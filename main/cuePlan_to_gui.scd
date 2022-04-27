var filePath = "/home/vincent/Downloads/Ablaufplan - Tagesplan.tsv";
var nameText = List.new, benniText = List.new, philippText = List.new, vincentText = List.new; //cuesText = List.new,
~cues = (
	lastCueChangeTime: SystemClock.seconds,
	makeGui: { |self|
		var win = Window.new(bounds: Rect(0,0,1920,480)).front;
		var gapOffset = 15;
		win.view.decorator = FlowLayout.new( win.view.bounds, 10@10, 10@20 );
		//StaticText(win.view, Rect(45, 10, win.view.bounds.width * (10/100) - gapOffset, 30)).string_("CUE").align_(\center);
		self.timerText = StaticText(win.view, Rect(45, 10, win.view.bounds.width * (10/100) - gapOffset, 30)).string_("CUE NOW").align_(\left);
		StaticText(win.view, Rect(45, 10, win.view.bounds.width * (20/100) - gapOffset, 30)).string_("BENNI").align_(\center);
		StaticText(win.view, Rect(45, 10, win.view.bounds.width * (20/100) - gapOffset, 30)).string_("PHILIPP").align_(\center);
		StaticText(win.view, Rect(45, 10, win.view.bounds.width * (50/100) - gapOffset, 30)).string_("VINCENT").align_(\center);
		2.do {
			/*cuesText.add(
			StaticText(win.view,Rect(10,10, win.view.bounds.width * (10/100) - gapOffset, 180))
			.background_(Color.white)
			.align_(\center)
			.font_(Font("Hacker", 50)); // 10 prozent
			);*/
			nameText.add(
				StaticText(win.view,Rect(10,10, win.view.bounds.width * (10/100) - gapOffset, 180))
				.background_(Color.white)
				.align_(\center)
				.font_(Font("Hacker", 36));
			);
			benniText.add(
				StaticText(win.view,Rect(10,10, win.view.bounds.width * (20/100) - gapOffset, 180)).background_(Color.white);
			);
			philippText.add(
				StaticText(win.view,Rect(10,10, win.view.bounds.width * (20/100) - gapOffset, 180)).background_(Color.white);
			);
			vincentText.add(
				StaticText(win.view,Rect(10,10, win.view.bounds.width * (50/100) - gapOffset, 180)).background_(Color.white).font_(Font("Hacker", 28));
			);
		};
		self.refreshTimer = SkipJack({
			var second = (SystemClock.seconds - self.lastCueChangeTime % 60).asInteger;
			var minute = (SystemClock.seconds - self.lastCueChangeTime / 60).asInteger;
			self.timerText.string_("CUE NOW %'%".format(minute, second));
		},1);
		self.win = win;
		self.win.view.keyDownAction = {|view, char, mod, unicode|
			if(unicode == 32){self.nextCue};
			if(unicode == 98){self.lastCue};
		};
	},
	cueFile: TabFileReader.read(filePath,true),
	textViews: (names: nameText, benni: benniText, philipp: philippText, vincent: vincentText), // cues: cuesText,
	mapping: [nil, nil, \names, \benni, \philipp, \vincent, nil, nil, nil],
	cueNow: 0,
	cueOffset: 4,
	inc: { |self| self.cueNow = self.cueNow + 1 },
	dec: { |self| self.cueNow = (self.cueNow - 1).clip(0,100)},
	sendCue: { |self| ~toBenni.sendMsg("/cue", self.cueNow); ~toPhilipp.sendMsg("/cue", self.cueNow) },
	refreshGUI: {|self|
		var readFrom = self.cueOffset + self.cueNow;
		self.lastCueChangeTime = SystemClock.seconds;
		self.cueFile[readFrom..(readFrom + 1)].do {|strArr, row|
			strArr.do {|txt, ix|
				if(self.mapping[ix].notNil){
					self.textViews[self.mapping[ix]][row].string_(txt)
				}
			}
		};
	},
	nextCue: {|self| self.inc; self.sendCue; {self.refreshGUI}.defer},
	lastCue: {|self| self.dec; self.sendCue; {self.refreshGUI}.defer}
);
~cues.makeGui;
{~cues.refreshGUI}.defer;
OSCdef(\receiveCues, {|msg|
	var newCue = msg[1];
	~cues.cueNow = newCue;
	{~cues.refreshGUI}.defer
}, '/cue').fix;
