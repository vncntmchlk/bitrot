x = TabFileReader.read("/home/vincent/Downloads/Ablaufplan - Tagesplan.tsv",true).postcs;

// size immer 7
x[5][3]

(
var cuesText = List.new, nameText = List.new, benniText = List.new, philippText = List.new, vincentText = List.new;
w = Window.new(bounds: Rect(0,0,2000,650)).front;
w.view.decorator = d = FlowLayout.new( w.view.bounds, 10@10, 0@20 );
StaticText(w.view, Rect(45, 10, w.view.bounds.width * (10/100) - 5, 30)).string_("CUE").align_(\center);
StaticText(w.view, Rect(45, 10, w.view.bounds.width * (15/100) - 5, 30)).string_("CUE NAME").align_(\center);
StaticText(w.view, Rect(45, 10, w.view.bounds.width * (25/100) - 5, 30)).string_("BENNI").align_(\center);
StaticText(w.view, Rect(45, 10, w.view.bounds.width * (25/100) - 5, 30)).string_("PHILIPP").align_(\center);
StaticText(w.view, Rect(45, 10, w.view.bounds.width * (25/100) - 5, 30)).string_("VINCENT").align_(\center);
3.do {
	cuesText.add(
		TextView(w.view,Rect(10,10, w.view.bounds.width * (10/100) - 5, 180)); // 10 prozent
	);
	nameText.add(
		TextView(w.view,Rect(10,10, w.view.bounds.width * (15/100) - 5, 180)); // 15 prozent
	);
	benniText.add(
		TextView(w.view,Rect(10,10, w.view.bounds.width * (25/100) - 5, 180)); // 25 prozent
	);
	philippText.add(
		TextView(w.view,Rect(10,10, w.view.bounds.width * (25/100) - 5, 180)); // 25 prozent
	);
	vincentText.add(
		TextView(w.view,Rect(10,10, w.view.bounds.width * (25/100) - 5, 180)); // 25 prozent
	);
};
~textViews = (
	cues: cuesText, names: nameText, benni: benniText, philipp: philippText, vincent: vincentText
);
~mapping = [nil, \cues, \names, \benni, \philipp, \vincent, nil];
)

(
x[4..6].do {|strArr, row|
	strArr.do {|txt, ix|
		if(~mapping[ix].notNil){
			~textViews[~mapping[ix]][row].setString(txt)
		}
	}
}
)
