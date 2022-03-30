// die NetAddr mit meiner IP musst du ändern zu
// ~zuVincent = NetAddr("127.0.0.1", 9004);

(
~toPhilipp = NetAddr("127.0.0.1", 9004);

OSCdef(\receiveNewMelody, {|msg|
	if(msg[1..].size == 16){
		~philippMelodie = msg[1..];
	}
}, "/melodyList").fix;
Pdefn(\onOffMelody, Pn(Plazy{Pseq(16.collect{0.35.coin}, 8)}));
~philippMelodie = (50..65);

OSCdef(\receiveNewBass, {|msg|
	if(msg[1..].size == 16){
		~philippBass = msg[1..];
	}
}, "/bassList").fix;
Pdefn(\onOffBass, Pn(Plazy{Pseq(16.collect{0.35.coin}, 8)}));
~philippBass = (40..55);
)


~melodyPlayer = Pbind(
	\dur, 1/8,
	\index, Pseq((0..15), inf),
	\onOff, Pdefn(\onOffMelody),
	\lag, 0.05,
	\midinote, Pfunc {|ev|
		if(ev.onOff){
			~toPhilipp.sendMsg("/melodyIndex", ev.index, 0);
			~philippMelodie[ev.index]
		}{
			Rest(60)
		};
	}
).play(quant: 2);

Pdefn(\onOffMelody, Pn(Plazy{Pseq(16.collect{0.35.coin}, inf)})); // immer die selbe wiederholen

~melodyPlayer.stop;

~bassPlayer = Pbind(
	\dur, 1/8,
	\index, Pseq((0..15), inf),
	\onOff, Pdefn(\onOffBass),
	\lag, 0.05,
	\midinote, Pfunc {|ev|
		if(ev.onOff){
			~toPhilipp.sendMsg("/bassIndex", ev.index, 0);
			~philippBass[ev.index]
		}{
			Rest(60)
		};
	}
).play(quant: 2);

Pdefn(\onOffBass, Pn(Plazy{Pseq(16.collect{0.35.coin}, inf)})); // immer die selbe wiederholen

~bassPlayer.stop;



