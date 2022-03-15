~circles.guiElements = ();
~circles.guiElements.resolution = [ 270, 392 ];
~circles.guiElements.offset = Point( 196, 135 ); //wird auch fuer rechts benutzt...
~circles.guiElements.fps = 25;
~circles.guiElements.res2 = ~circles.guiElements.resolution * 2;

~circles.guiElements.window = Window("circles", Rect(0, 0, ~circles.guiElements.resolution[1] * 4 + 8, ~circles.guiElements.resolution[0] * 4 + 6));
~circles.guiElements.window.view.background = Color.black;
~circles.guiElements.window.front;

~circles.melodieCircle.view = UserView(~circles.guiElements.window, Rect(2, 2, ~circles.guiElements.res2[1], ~circles.guiElements.res2[0])).background_(Color.white);
~circles.chordsBassCircle.view = UserView(~circles.guiElements.window, Rect(2, ~circles.guiElements.res2[0] + 4, ~circles.guiElements.res2[1], ~circles.guiElements.res2[0])).background_(Color.white);
/*~chordsBassCircle.view = UserView(~circles.guiElements.window, Rect(~circles.guiElements.res2[1] + 4, 2, ~circles.guiElements.res2[1], ~circles.guiElements.res2[0])).background_(Color.white);
~arpCircle.view = UserView(~circles.guiElements.window, Rect(~circles.guiElements.res2[1] + 4, ~circles.guiElements.res2[0] + 4, ~circles.guiElements.res2[1], ~circles.guiElements.res2[0])).background_(Color.white);*/

~cues = (
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
~cues.setCue;
//~cues.view.setFont(Font("Hack", 24),0);

~circles.guiElements.refreshPoints = SkipJack(
	updateFunc: {~circles.guiElements.window.refresh},
	dt: (1 / ~circles.guiElements.fps)
);

[~circles.melodieCircle, ~circles.chordsBassCircle].do {|instrumentCircle| //~chordsBassCircle, ~arpCircle
	instrumentCircle.view.drawFunc = {
		Pen.scale(2,2);
		Pen.stringAtPoint(instrumentCircle.guiText, 4@5, Font("Hack", 16), Color.black);
		Pen.use {
			var hits = List.new;
			instrumentCircle.circs.do { |ci|
				if(ci.sharedValues.onOff.asBoolean){
					Pen.color = Color.black();
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
						Pen.color = Color.black;
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