thisProcess.openUDPPort(9005)

OSCdef(\philippListe, {|msg|
	msg.postln;
	if(msg[1..].size == 16){
		~melodie = msg[1..];
	}
}, "/liste").fix

~toPhilipp = NetAddr("192.168.1.102", 9004)


~toPhilipp.sendMsg("/index", 1)
~melodie = (60..75)

s.latency = 0.05
x = Pbind(
	\dur, 1/8,
	\index, Pseq((0..15),inf),
	\midinote, Pfunc{|ev| ~melodie[ev.index] }, //PLseq(\melodie),
	\amp, PLseq(\rhy),
	\finish, {|ev|
		topEnvironment[\toPhilipp].sendMsg("/index", (ev.index + 1).mod(16).postln);
		ev
	}
).play(quant: 2)

x.stop


~rhy = 16.collect{[0,0.015].wchoose([0.2,0.8])}

x = PmonoArtic(\default,
	\dur, 1/4,
	\legato, 1.4,
	\index, Pseq((0..15),inf),
	\midinote, Pfunc{|ev| ~melodie[ev.index.linlin(0, 15, 0, 5.99)] }, //PLseq(\melodie),
	\amp, PLseq(\rhy),
/*	\finish, {|ev|
		topEnvironment[\toPhilipp].sendMsg("/index", (ev.index + 1).mod(16));
		ev
	}*/
).play

x = Pbind(
	\type, \oscMidi,
	\dur, 1/8,
	\chan, 0,
	\netAddr, ~toBenni,
	\index, Pseq((0..15),inf),
	\midinote, Pfunc{|ev| ~melodie[ev.index] }, //PLseq(\melodie),
	\amp, PLseq(\rhy),
	\finish, {|ev|
		topEnvironment[\toPhilipp].sendMsg("/index", (ev.index + 1).mod(16));
		ev
	}
).play(quant: 2)