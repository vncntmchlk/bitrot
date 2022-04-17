~circles.guiElements.resolution = [ 270, 392 ];
~circles.guiElements.fps = 25;
~circles.guiElements.res2 = ~circles.guiElements.resolution * 2;
// ~circles.guiElements.noteMapping = (0, 12 .. 120).collect (_ + Scale.major.degrees).flat;

["melodie", "bass", "melodie2"].do { |name|
	var symWindow = (name ++ "Window").asSymbol;
	var symCircle = (name ++ "Circle").asSymbol;
	var symRefreshPoints = (name ++ "RefreshPoints").asSymbol;
	var symNotesView = (name ++ "NotesView").asSymbol;
	var symNoteHits = (name ++ "NoteHits").asSymbol;
	var symNoteHitColor = (name ++ "NoteHitColor").asSymbol;
	var makeWindowBigger = 0; //300

	var center;
	var innerRad = 250;
	var noteLines = 31;
	var lineDist = 5;
	var lineAlphaMap = Env([0.1,0.5,0.1],[1,1]).asSignal(noteLines);
	var midinoteLineOffset = (bass: 24, melodie: 24, melodie2: 17)[name.asSymbol];
	var drawWedge = { |startAngle, sweepLength, hit, hitColor|
		noteLines.do{ |i|
			Pen.addAnnularWedge(
				center,
				innerRad + (i * lineDist),
				innerRad + ((i + 1) * lineDist),
				startAngle,
				sweepLength
			);
			if(i == hit){
				Pen.color = hitColor;
				Pen.fill
			}{
				Pen.color = Color.grey(1,lineAlphaMap[i]);
				Pen.stroke
			};
		}
	};

	~circles.guiElements[symWindow] = Window(name,
		Rect(0, 0, ~circles.guiElements.res2[1] + makeWindowBigger,~circles.guiElements.res2[0] + makeWindowBigger), false, ~guiBorder
	).autoRememberPosition(\bitrot, name.asSymbol);
	~circles.guiElements[symWindow].view.background = ~guiBackgroundColor;
	~circles[symCircle].view = UserView(
		~circles.guiElements[symWindow],
		Rect(makeWindowBigger/2, makeWindowBigger/2, ~circles.guiElements.res2[1], ~circles.guiElements.res2[0])).background_(Color.gray(0,0)
	);
	~circles.guiElements[symRefreshPoints] = SkipJack(
		updateFunc: {~circles[symCircle].view.refresh},
		dt: (1 / ~circles.guiElements.fps),
		autostart: false
	);
	~circles.guiElements[symNotesView] = UserView(~circles.guiElements[symWindow],
		Rect(0, 0, ~circles.guiElements.res2[1] + makeWindowBigger,~circles.guiElements.res2[0] + makeWindowBigger)
	);

	center = ((~circles.guiElements.res2[1] + makeWindowBigger)/1 + 0)@((~circles.guiElements.res2[0] + makeWindowBigger/1) + 0);

	~circles.guiElements[symNoteHits] = Set.new;
	~circles.guiElements[symNoteHitColor] = Color.red(0.5,0.2) ! 16;
	~circles.guiElements[symNotesView].drawFunc= {
		Pen.use {
			Pen.scale(0.5, 0.5);
			~circles[symCircle].taktLen.do {|ix|
				var startAng = (ix * (360 / ~circles[symCircle].taktLen) - 180).degrad;
				var midinn = ~circles[symCircle].noteArray[ix];
				var sweep =  (360 / ~circles[symCircle].taktLen).degrad;
				var hitColor = if(~circles.guiElements[symNoteHits].includes(ix)){
					~circles.guiElements[symNoteHitColor][ix]
				}{
					Color.grey(1,0.75)
				};
				drawWedge.(startAng, sweep, (midinn - noteLines - midinoteLineOffset) % noteLines, hitColor)
				// (midinn - noteLines) % noteLines -> 60 ist in der mitte
				// (midinn - noteLines - 12) % noteLines -> 60 ist unten
			};
		};
	};
};

[~circles.melodieCircle, ~circles.bassCircle, ~circles.melodie2Circle].do {|instrumentCircle|
	instrumentCircle.view.drawFunc = {
		// Pen.scale(2,2);
		Pen.stringAtPoint(instrumentCircle.guiText, 4@5, Font("Hack", 16), Color.white);
		Pen.use {
			var hits = List.new;
			Pen.translate(instrumentCircle.view.bounds.size.width * 0.25, instrumentCircle.view.bounds.size.height * 0.25);
			instrumentCircle.circs.do { |ci|
				if(ci.sharedValues.onOff.asBoolean){
					Pen.color = Color.grey(1, 0.4);
					Pen.addOval(Rect(
						~circles.guiElements.offset.x - ci.radius,
						~circles.guiElements.offset.y - ci.radius,
						ci.circumference,
						ci.circumference));
					Pen.width = 5;
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
				Pen.color = Color.grey(0,1);
			}{
				Pen.color = Color.grey(1,0.9);
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
