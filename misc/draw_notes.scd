// besser als die ganzen noten viertel ohne stem?
// \\override Voice.Stem.color = #(x11-color 'white)
(
(0..127).do { |i|
	var note = FoscNote(i, 4).str;
	var fileString = "
\\language \"english\"
\\version \"2.22.1\"
{
\\override NoteHead.style = #'vaticana.punctum
\\override Accidental #'stencil = ##f
\\override NoteHead.extra-offset =  #'(5 . 0)
\\override Staff.StaffSymbol.staff-space = #1.7
\\override Staff.StaffSymbol.thickness = #0.33
\\override Staff.StaffSymbol.line-count = #13
\\override Staff.LedgerLineSpanner.color = #(x11-color 'white)
\\override Voice.Accidental.color = #(x11-color 'white)
\\override Staff.StaffSymbol.color = #(x11-color 'white)
\\override Staff.Clef.color = #(x11-color 'white)
\\omit Staff.Clef
\\override Voice.NoteHead.color = #(x11-color 'white)
\\override Voice.Stem.transparent = ##t
\\override Staff.BarLine.color = #(x11-color 'white)
\\time 4/4
\\omit Staff.TimeSignature
\\omit Staff.BarLine
%
}
".format(note);
	fileString.postln;
	File.use(
		"/home/vincent/Desktop/lilypond_test/melodie" +/+ i ++ ".ly", "w", { |f| f.write(fileString);
		}
	);

};
)

~allWhite = (0, 12 .. 120).collect (_ + Scale.major.degrees).flat;

// \\aikenHeads
(
(0..127).do { |i|
	var note = FoscNote(i, 4).str;
	var fileString = "
\\language \"english\"
\\version \"2.22.1\"
{
  \\override NoteHead.style = #'vaticana.punctum
  \\override Accidental #'stencil = ##f
  \\override NoteHead.extra-offset =  #'(13 . 0)
  \\override Staff.StaffSymbol.staff-space = #0.7
  \\override Staff.StaffSymbol.thickness = #0.33
  \\override Staff.StaffSymbol.line-count = #28
  \\override Staff.LedgerLineSpanner.color = #(x11-color 'white)
  \\override Voice.Accidental.color = #(x11-color 'white)
  \\override Staff.StaffSymbol.color = #(x11-color 'white)
  \\override Staff.Clef.color = #(x11-color 'white)
  \\omit Staff.Clef
  \\override Voice.NoteHead.color = #(x11-color 'white)
  \\override Voice.Stem.transparent = ##t
  \\override Staff.BarLine.color = #(x11-color 'white)
  \\time 4/4
  \\omit Staff.TimeSignature
  \\omit Staff.BarLine
  %
}
".format(note);
	fileString.postln;
	File.use(
		"/home/vincent/Desktop/lilypond_test/melodie" +/+ i ++ ".ly", "w", { |f| f.write(fileString);
		}
	);

};
)


// anschliessend lilypond -fsvg -dcrop *.ly
// cp *.cropped.svg /home/vincent/Repos/bitrot/bitrot/ca_combined/svg_g_clef
// rm *[!cropped].svg // brauch man nicht mehr



(
(0..127).do { |i|
	var note = FoscNote(i, 1/4).str;
	var fileString = "
\\language \"english\"
{
  \\override Staff.LedgerLineSpanner.color = #(x11-color 'white)
  \\override Voice.Accidental.color = #(x11-color 'white)
  \\override Staff.StaffSymbol.color = #(x11-color 'white)
  \\override Staff.Clef.color = #(x11-color 'white)
  \\override Voice.NoteHead.color = #(x11-color 'white)
  \\override Voice.Stem.transparent = ##t
  \\override Staff.BarLine.color = #(x11-color 'white)
  \\clef bass
  \\time 4/4
  \\omit Staff.TimeSignature
  \\omit Staff.BarLine
  %
}
".format(note);
	fileString.postln;
	File.use(
		"/home/vincent/Desktop/lilypond_test/bass" +/+ i ++ ".ly", "w", { |f| f.write(fileString);
		}
	);

};
)

//cp *.cropped.svg /home/vincent/Repos/bitrot/bitrot/ca_combined/svg_f_clef



// mit noten als zahl
(
(0..127).do { |i|
	var note = FoscNote(i, 4).str;
	var fileString = "
\\language \"english\"
\\version \"2.22.1\"
{
  \\override Accidental #'stencil = ##f
  \\override Voice.NoteHead.stencil = #ly:text-interface::print
  \\override Voice.NoteHead.text = \\markup \\smaller \\lower #0.5 \"%\"
  \\override Voice.NoteHead.extra-offset =  #'(13 . 0)
  \\override Staff.StaffSymbol.staff-space = #0.7
  \\override Staff.StaffSymbol.thickness = #0.5
  \\override Staff.StaffSymbol.line-count = #28
  \\override Staff.LedgerLineSpanner.color = #(x11-color 'white)
  \\override Voice.Accidental.color = #(x11-color 'white)
  \\override Staff.StaffSymbol.color = #(x11-color 'white)
  \\override Staff.Clef.color = #(x11-color 'white)
  \\omit Staff.Clef
  \\override Voice.NoteHead.color = #(x11-color 'white)
  \\override Voice.Stem.transparent = ##t
  \\override Staff.BarLine.color = #(x11-color 'white)
  \\time 4/4
  \\omit Staff.TimeSignature
  \\omit Staff.BarLine
  %
}
".format(i, note);
	fileString.postln;
	File.use(
		"/home/vincent/Desktop/lilypond_test/melodie" +/+ i ++ ".ly", "w", { |f| f.write(fileString);
		}
	);

};
)