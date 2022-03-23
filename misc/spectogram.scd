a = [1,2,3]

a = a.shift(-1, 55)

(1..512).collect{|v| v.log / 511.log * 512}.last

10.log * 10
133.log10

133.log / 10.log

logₐ(x) = ln(x) / ln(a)
// spectrogram in a window
(
w = Window.new("spectrogram".scramble, Rect(10,10, 160, 300)).front;
a = Spectrogram.new(w, Rect(10, 10, 150, 260));
a.start;
a.intensity = 50;
// {SinOsc.ar(MouseY.kr(50,1000))}.play;
{SoundIn.ar([2,3])}.play;
)


b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav"); // remember to free the buffer later.

SynthDef(\help_PlayBuf, {| out = 0, bufnum = 0 |
    Out.ar(out,
        PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum),loop:1, doneAction: Done.freeSelf)
    )
}).play(s, [\out, 0, \bufnum, b]);

~toBenni.sendMsg("/bitrotData", "fftXbins", *[4, 8, 16, 32, 64]) // bins
~toBenni.sendMsg("/bitrotData", "fftXbins", *[8, 16, 32, 64, 128]) // bins


Rect(10, 10, 260, 10).height

// spectrogram in a window
(
w = Window.new("spectrogram".scramble, Rect(10,10, 300, 60)).front;
a = Spectrogram3.new(w, Rect(10, 10, 260, 50));
a.start;
a.intensity = 50;
// {SinOsc.ar(MouseY.kr(50,1000))}.play;
{SoundIn.ar([2,3])}.play;
)

{SoundIn.ar([2,3])}.play;