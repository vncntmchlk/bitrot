// es ist nur 1 spectogram auf einmal am spielen daher:
// methode um eines zu starten im modus hori oder verti
// methode um es zu schliessen und synths vom server zu stoppen usw.
// evtl window fade in und out beim oeffnen und schliessen

// auf dem ganzen unteren bildschirm
(
w = Window.new("spectrogram", Rect(1920,0, 1920, 480),border:false)
.background_(Color.grey(0,0))
.front;
a = Spectrogram.new(w, Rect(0,0, 1920, 480)).background_(Color.grey(0,0));
a.start;
a.intensity = 50;//50;
//{SinOsc.ar(MouseY.kr(50,1000))}.play;
{SoundIn.ar([12,13])}.play;
)
// klein und vertikal, scrolling
(
w = Window.new("spectro", Rect(10,10, 300, 200)).background_(Color.grey(0,0)).front;
a = Spectrogram3.new(w, Rect(0, 0, 300, 200)).background_(Color.grey(0,0));
a.start;
a.intensity = 50;
// {SinOsc.ar(MouseY.kr(50,1000))}.play;
{SoundIn.ar([12,13])}.play;
)
