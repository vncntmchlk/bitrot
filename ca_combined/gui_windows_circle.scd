~circles.guiElements.resolution = [ 270, 392 ];
~circles.guiElements.fps = 25;
~circles.guiElements.res2 = ~circles.guiElements.resolution * 2;
~circles.guiElements.noteMapping = (0, 12 .. 120).collect (_ + Scale.major.degrees).flat;



["melodie", "bass", "melodie2"].do { |name|
	var symWindow = (name ++ "Window").asSymbol;
	var symCircle = (name ++ "Circle").asSymbol;
	var symRefreshPoints = (name ++ "RefreshPoints").asSymbol;
	var symNotesView = (name ++ "NotesView").asSymbol;
	var symNoteHits = (name ++ "NoteHits").asSymbol;
	var symNoteHitColor = (name ++ "NoteHitColor").asSymbol;
	var makeWindowBigger = 200;

	var center;
	var innerRad = 250;
	var noteLines = 24;
	var lineDist = 5;
	var lineAlphaMap = Env([0.1,0.5,0.1],[1,1]).asSignal(noteLines);
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


	~circles.guiElements[symWindow] = Window(name, Rect(0, 0, ~circles.guiElements.res2[1] + makeWindowBigger,~circles.guiElements.res2[0] + makeWindowBigger));
	~circles.guiElements[symWindow].view.background = Color.black;
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

	center = ((~circles.guiElements.res2[1] + makeWindowBigger)/2 + 0)@((~circles.guiElements.res2[0] + makeWindowBigger/2) + 0);

	~circles.guiElements[symNoteHits] = Set.new;
	~circles.guiElements[symNoteHitColor] = Color.red(0.5,0.2) ! 16;
	~circles.guiElements[symNotesView].drawFunc= {
		~circles[symCircle].taktLen.do {|ix|
			var startAng = (ix * (360 / ~circles[symCircle].taktLen) - 180).degrad;
			var midinn = ~circles[symCircle].noteArray[ix];
			var sweep =  (360 / ~circles[symCircle].taktLen).degrad;
			var hitColor = if(~circles.guiElements[symNoteHits].includes(ix)){
				~circles.guiElements[symNoteHitColor][ix]
			}{
				Color.grey(1,0.75)
			};
			// set the Color
			drawWedge.(startAng, sweep, (midinn - noteLines - 6) % noteLines, hitColor)
			// (midinn - noteLines) % noteLines -> 60 ist in der mitte
			// (midinn - noteLines - 6) % noteLines -> 54 ist in der mitte
		};
	};
};



/*["melodie", "bass", "melodie2"].do { |name|
var symWindow = (name ++ "Window").asSymbol;
var symCircle = (name ++ "Circle").asSymbol;
var symRefreshPoints = (name ++ "RefreshPoints").asSymbol;
var symNotesView = (name ++ "NotesView").asSymbol;
var symNoteHits = (name ++ "NoteHits").asSymbol;
var symNoteHitColor = (name ++ "NoteHitColor").asSymbol;
var symNoteImages = (
\melodie: \noteImgsGClef,
\melodie2: \noteImgsGClef,
\bass: \noteImgsFClef
)[name.asSymbol];
var noteSvgOffset = Point(-35,-35);
var makeWindowBigger = 200;
~circles.guiElements[symWindow] = Window(name, Rect(0, 0, ~circles.guiElements.res2[1] + makeWindowBigger,~circles.guiElements.res2[0] + makeWindowBigger));
~circles.guiElements[symWindow].view.background = Color.black;
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

~circles.guiElements[symNoteHits] = Set.new;
~circles.guiElements[symNoteHitColor] = Color.red(0.5,0.2) ! 16;
~circles.guiElements[symNotesView].drawFunc= {
~circles[symCircle].taktLen.do {|ix|
var rad = (ix * (360 / ~circles[symCircle].taktLen) - 180).degrad;
var pt = Polar(280, rad).asPoint.translate(
(~circles[symCircle].view.bounds.width/2 + 30)@(~circles[symCircle].view.bounds.height/2 + 35)
); // 15 25
var midinn = ~circles[symCircle].noteArray[ix];
var img = ~circles.guiElements[symNoteImages][~circles.guiElements.noteMapping.clipAt(midinn - 24)];
// var img = ~circles.guiElements[symNoteImages][~circles[symCircle].noteArray][ix];
Pen.use {
Pen.rotate(rad + 90.degrad, pt.x + (img.width/2), pt.y + (img.height/2));

//Pen.rotate((360/16).degrad, ~circles.guiElements[symNotesView].bounds.width, ~circles.guiElements[symNotesView].bounds.height);
Pen.drawImage(pt ,img); //pt.translate(noteSvgOffset)
// ~circles.guiElements[symNoteImages][~circles[symCircle].noteArray][ix].drawAtPoint(pt.translate(noteSvgOffset));
if(~circles.guiElements[symNoteHits].includes(ix)){
Pen.color_(~circles.guiElements[symNoteHitColor][ix]);
Pen.addRect(Rect(pt.x, pt.y, 55, 45)); // 75 35
Pen.fill
}
}
};
//~circles.guiElements[symNoteHits].clear;
// sollte per drawNotesOff geregelt werden
};
};*/

{
	var imgPath = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "svg_g_clef";
	~circles.guiElements.noteImgsGClef = (0..127).collect {|nn|
		Image.openSVG(imgPath +/+ nn ++ ".cropped.svg")
	};
}.value;

{
	var imgPath = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "svg_f_clef";
	~circles.guiElements.noteImgsFClef = (0..127).collect {|nn|
		Image.openSVG(imgPath +/+ nn ++ ".cropped.svg")
	};
}.value;

[~circles.melodieCircle, ~circles.bassCircle, ~circles.melodie2Circle].do {|instrumentCircle|
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
				Pen.color = Color.green(0.5);
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
