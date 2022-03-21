//~circles.guiElements = ();
~circles.guiElements.resolution = [ 270, 392 ];
//~circles.guiElements.offset = Point( 196, 135 ); //wird auch fuer rechts benutzt...
~circles.guiElements.fps = 25;
~circles.guiElements.res2 = ~circles.guiElements.resolution * 2;

["melodie", "bass", "chords"].do { |name|
	var sym = (name ++ "Window").asSymbol;
	var symCircle = (name ++ "Circle").asSymbol;
	var symRefreshPoints = (name ++ "RefreshPoints").asSymbol;
	~circles.guiElements[sym] = Window(name, Rect(0, 0, ~circles.guiElements.res2[1] + 100,~circles.guiElements.res2[0] + 100));
	~circles.guiElements[sym].view.background = Color.black;
	~circles[symCircle].view = UserView(~circles.guiElements[sym], Rect(50, 50, ~circles.guiElements.res2[1], ~circles.guiElements.res2[0])).background_(Color.gray(0,0));

	~circles.guiElements[symRefreshPoints] = SkipJack(
		updateFunc: {~circles[symCircle].view.refresh},
		dt: (1 / ~circles.guiElements.fps),
		autostart: false
	);
};

~circles.guiElements.notesView = UserView(~circles.guiElements.melodieWindow,
	Rect(0, 0, ~circles.guiElements.res2[1] + 100,~circles.guiElements.res2[0] + 100)
);
~circles.guiElements.noteImgs = (0..127).collect {|nn|
	Image.open("/home/vincent/Repos/bitrot/bitrot/pngs" +/+ nn ++ ".png")
};
~circles.guiElements.notesHits = Set.new;
~circles.guiElements.noteHitColor = Color.red(0.5,0.2);
~circles.guiElements.notesView.drawFunc= {
	16.do {|ix|
		var rad = (ix * 22.5 - 180).degrad;
		var pt = Polar(280, rad).asPoint.translate(
			(~circles.melodieCircle.view.bounds.width/2 + 15)@(~circles.melodieCircle.view.bounds.height/2 + 25)
		);
		~circles.guiElements.noteImgs[~circles.melodieCircle.noteArray][ix].drawAtPoint(pt);
		if(~circles.guiElements.notesHits.includes(ix)){
			Pen.color_(~circles.guiElements.noteHitColor);
			Pen.addRect(Rect(pt.x, pt.y, 75, 35));
			Pen.fill
		}
	};
	~circles.guiElements.notesHits.clear;
};

/*~circles.guiElements.melodieWindow = Window("melodie", Rect(0, 0, ~circles.guiElements.res2[1] + 100,~circles.guiElements.res2[0] + 100));
~circles.guiElements.melodieWindow.view.background = Color.black;
// ~circles.guiElements.melodieWindow.front;

~circles.guiElements.bassWindow = Window("bass", Rect(0, 0, ~circles.guiElements.res2[1] + 100,~circles.guiElements.res2[0] + 100));
~circles.guiElements.bassWindow.view.background = Color.black;

~circles.guiElements.chordsWindow = Window("chords", Rect(0, 0, ~circles.guiElements.res2[1] + 100,~circles.guiElements.res2[0] + 100));
~circles.guiElements.chordsWindow.view.background = Color.black;

~circles.melodieCircle.view = UserView(~circles.guiElements.melodieWindow, Rect(50, 50, ~circles.guiElements.res2[1], ~circles.guiElements.res2[0])).background_(Color.gray(0,0));
~circles.bassCircle.view = UserView(~circles.guiElements.bassWindow, Rect(50, 50, ~circles.guiElements.res2[1], ~circles.guiElements.res2[0])).background_(Color.gray(0,0));
~circles.chordsCircle.view = UserView(~circles.guiElements.bassWindow, Rect(50, 50, ~circles.guiElements.res2[1], ~circles.guiElements.res2[0])).background_(Color.gray(0,0));*/





/*~cues = (
list: [
"Clicks Intro; Resonance voll -> Staccato Akkorde (instr 0)",
"Clicks ausdünnen -> Bass (langsam, legato) -> Clicks raus, bass filter auf,Benni schaut: KICK! UND LONG PLUCKS(INSTR 1)! ->bass schneller, Akkorde weniger und zu Legato",
"Volle Verzerrung BD und Bass -> BD raus, Bass raus",
"Filter auf den Chords -> Arpeggiator (einzeln)",
"Plucks sind kurz -> Kick & Bass rein",
"Kick dunkel (srr) -> Kick raus, Bass raus",
"Arp solo, simpel & durchgängig (Philipp). SLOW Kick rein(INSTR 1!!)",
"Vibrato voll -> kick raus; Glide hoch -> Arp Kreise raus bis auf äußeren",
"Arp viele noteOns, Klicks kommen rein (10er Quant)",
"Phaser, gliss nach oben -> Drums (instr 0 bis auf SNARE, halftime instr 1) dazu (hh erst), Chords dazu (instr 1)",
"letzter Arp raus, Clicks ausdünnen; Quant auf 8; Clicks raus, Akkorde pulsig",
"bass dazu; Chords werden langsamer; bis Auf chords & kick alle wieder raus (auch bass raus!), chords auf instrument 1 -> auf lange release von chords warten!",
"chords wieder schneller für philipp; und wieder langsamer",
"chords slow att -> vereinzelt kicks; kicks hören auf, chords hören auf"
],
view: StaticText(~circles.guiElements.window, Rect(~circles.guiElements.res2[1] + 6, ~circles.guiElements.res2[0] + 4, ~circles.guiElements.res2[1], ~circles.guiElements.res2[0])).background_(Color.white).align_(\topLeft).font_(Font("Hack", 24)),
cnt: 0,
inc: { |self| self.cnt = self.cnt + 1 },
dec: { |self| self.cnt = (self.cnt - 1).clip(0,100)},
setCue: {|self|
{
self.view.string = (
"--CUES--\n\nNOW: " ++
self.list[self.cnt] ++
"\n\n\n\nNEXT: " ++ self.list[self.cnt + 1]);
}.defer
},
nextCue: {|self| self.inc; self.setCue},
lastCue: {|self| self.dec; self.setCue}
);
~cues.view.parent.keyDownAction = {|view, char, mod, unicode|
if(unicode == 32){~cues.nextCue};
if(unicode == 98){~cues.lastCue};
};
~cues.setCue;*/



[~circles.melodieCircle, ~circles.bassCircle, ~circles.chordsCircle].do {|instrumentCircle| //~chordsBassCircle, ~arpCircle
	instrumentCircle.view.drawFunc = {
		Pen.scale(2,2);
		Pen.stringAtPoint(instrumentCircle.guiText, 4@5, Font("Hack", 16), Color.white);
		Pen.use {
			var hits = List.new;
			instrumentCircle.circs.do { |ci|
				if(ci.sharedValues.onOff.asBoolean){
					Pen.color = Color.white();
					Pen.addOval(Rect(
						~circles.guiElements.offset.x - ci.radius,
						~circles.guiElements.offset.y - ci.radius,
						ci.circumference,
						ci.circumference));
					Pen.stroke;
					if(ci.muteNow.not){
						Pen.color = ci.guiColor;
						if(ci.guiHit > 0){
							hits.add([
								Rect(*(
									Point(ci.radius,0).rotate((ci.testAngle - 180).degrad).translate(~circles.guiElements.offset - (ci.guiHit * 0.5)).asArray  ++ [ci.guiHit, ci.guiHit]
								)),
								ci.guiColor
							]);
							ci.guiHit = ci.guiHit - 8;
						}{
							Pen.addOval(
								Rect(*(
									Point(ci.radius,0).rotate((ci.testAngle - 180).degrad).translate(~circles.guiElements.offset - 3).asArray  ++ [6, 6]
								))
							);
						};
						Pen.fill;
					}{
						Pen.color = Color.white;
						Pen.addRect(
							Rect(*(
								Point(ci.radius,0).rotate((ci.testAngle - 180).degrad).translate(~circles.guiElements.offset - 2).asArray  ++ [2, 8]
							))
						);
						Pen.fill;
					};
				};
			};
			hits.do {|arr| Pen.color = arr[1]; Pen.addOval(arr[0]); Pen.fill};

			if(instrumentCircle.sharedValues.freezeMe.asBoolean){
				Pen.color = Color.black();
			}{
				Pen.color = Color.green();
			};
			instrumentCircle.points.do {|p|
				Pen.addRect(
					Rect(*((p - 3) ++ [6, 6]))
				);
			};
			Pen.fill;
		};
	};
};

//besser dass rpi immer sendet
/*~circles.sharedEvAll = OSCSharedEvent.new(netAddr: ~localHost, prefix: "circlesAll");
~circles.sharedEvAll.onOff = 0;
~circles.sharedEvAll.makeOSCdefsForKeys((
onOff: {|val|
if(val.asBoolean){
~rpiAddr.sendMsg("/circles", 1);
~circles.guiElements.refreshPoints.start;
{~circles.guiElements.melodieWindow.visible_(true)}.defer
}{
~rpiAddr.sendMsg("/circles", 0);
~circles.guiElements.refreshPoints.stop;
{~circles.guiElements.melodieWindow.visible_(false)}.defer
}
}
));
~circles.sharedEvAll.sendAll;*/