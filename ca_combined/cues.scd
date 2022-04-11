var cuesList = [
	// 0
	(name: "Prep", benni: "Denoise 100, Master 0"),
	// 1
	(name: "Atmo", benni: "Start Clip 7,
slow Master -> 100,
slow Denoise -> 0,
gefühl hin und zurück bis komplett hörbar
-> Vincent", vincent: "Start Clip 7"),
	// 2
	(name: "looping startet", vincent: "sample loop von 8 bis 1 sek, pro loop andere fft bins. clicks dazu, fft link von clip loop zu rhythm, CA. loop wird wieder länger
-> Benni"),
	// 3
	(name: "Atmo löst sich auf", vincent: ""),
	// 4
	(benni: "srr 100r (3-4 Töne)
disCons -> F", vincent: "fft wieder entkoppeln vom rhythmus, pro sekunde ändern und anschließend fft zeug aus -> Benni,
fftrange auf hoch"),
	// 5
	(benni: "x-fade atmo x Bass
-> vincent
x-fade clicks wet x dry", vincent: "Bass kommt rein -> Benni, -> zurueck, clip aus , bänder wieder auf sodass das noise zur Bass wird."),
	// 6
	(name: "Bass und Clicks", philipp: "Bassgrenzen 30 - 60, disConstruct, center ganz links, spread ca. 1 Uh
cCons -> cDim", vincent: "bisschen variationen beim bass, fft zu block or pass, rhythm 8er loop, dann cue geben"),
	// 7
	(name: "Bass entwicklung", benni: "(Vincent)
Master Bitcrush 50", philipp: "F -> cCons
-> vincent", vincent: "auf philipp reagieren; bass von 2 toenen zu 4 toenen"),
	// 8
	(name: "Melodie kommt rein", benni: "Master Bitcrush 50 -> 0;
melody fade in, release 100 ->25", philipp: "
cDim", vincent: "(davor auf philipp warten) benni -> Melodie startet; bass wird simple (steps 4); rhy mehr steps weniger speed 16/4")
	// 9
	(name: "", philipp: "wechsel h und fis", vincent: "")
];


~cues = (
	cuesList: cuesList ++ (() ! 20),
	makeGui: { |self|
		self.win = Window.new("cues", Rect(0, 0, 1000, 600));
		self.txtVincent = StaticText(self.win, Rect(0,0,1000,300))
		.background_(Color.red(1,0.1))
		.align_(\topLeft)
		.font_(Font("Hack", 22));
		self.txtBenni = StaticText(self.win, Rect(0,300,1000,150))
		.background_(Color.magenta(1,0.1))
		.align_(\topLeft)
		.font_(Font("Hack", 14));
		self.txtPhilipp = StaticText(self.win, Rect(0,450,1000,150))
		.background_(Color.cyan(1,0.1))
		.align_(\topLeft)
		.font_(Font("Hack", 14));
		self.win.view.keyDownAction = {|view, char, mod, unicode|
			if(unicode == 32){self.nextCue};
			if(unicode == 98){self.lastCue};
		};
		self.win.front
	},
	cnt: 0,
	inc: { |self| self.cnt = self.cnt + 1 },
	dec: { |self| self.cnt = (self.cnt - 1).clip(0,100)},
	sendCue: { |self| ~toBenni.sendMsg("/cue", self.cnt) },
	setCue: {|self|
		//self.sendCue;
		{
			var cl = self.cuesList[self.cnt];
			self.txtVincent.string = "CUE: " ++ self.cnt ++ " " ++ (cl.name ?? "")
			++ "\n\n" ++ (cl.vincent ?? "");
			self.txtBenni.string = "benni: " ++ (cl.benni ?? "");
			self.txtPhilipp.string = "philipp: " ++ (cl.philipp ?? "");
		}.defer
	},
	nextCue: {|self| self.inc; self.setCue},
	lastCue: {|self| self.dec; self.setCue}
);
~cues.makeGui;
