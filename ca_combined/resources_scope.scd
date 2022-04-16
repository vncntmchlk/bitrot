s.latency= 0.05;
s.waitForBoot{
	~scopeGUI = ();
	~scopeGUI.inputChannels = [4,5];
	~scopeGUI.winSize = 800; //global window size
	~scopeGUI.buffer = Buffer.alloc(s, ~scopeGUI.winSize, 1);
	~scopeGUI.options = ();
	SynthDef(\avTrk, {|in= 0, bufnum, rate= 40, sample= 1|
		var z = In.ar(in, 1);
		var trig= Impulse.ar(rate*0.92);	//compensate
		var index= Phasor.ar(trig, sample, 0, BufFrames.ir(bufnum)-1);
		BufWr.ar(z, bufnum, index, 0);
		SendTrig.ar(trig, 0, bufnum);
	}).add;
	SynthDef(\avSnd, {|out= 0, bufnum|
		Out.ar(out, SoundIn.ar(~scopeGUI.inputChannels))
	}).add;
	s.sync;
	//--interface
	~scopeGUI.options.trails= 1;
	~scopeGUI.options.speed= 0;
	~scopeGUI.options.sample= 1;
	~scopeGUI.options.amp= 0.5;
	~scopeGUI.options.version= 0;

	~scopeGUI.startGui = {
		//--setup
		var width= ~scopeGUI.winSize, height= ~scopeGUI.winSize;
		var w= Window("Example18 - waveform", Rect(99, 99, width, height),false,~guiBorder)
		.background_(Color.grey(0,0));
		var u= UserView(w, Rect(0, 0, width, height));

		//--variables
		var theta= 0;
		var fps= 60;
		var arr= Array.fill(~scopeGUI.winSize, 0);		//same as half windowsize above
		var o= OSCFunc({|m|
			if(m[2]==0, {			//redraw once for each cycle of amps
				~scopeGUI.buffer.getn(0, ~scopeGUI.winSize-1, {|data| {arr= data; u.refresh}.defer});
			});
		}, '/tr', s.addr);
		var trk= Synth(\avTrk, [\in, 0, \bufnum, ~scopeGUI.buffer, \rate, fps]);
		var snd= Synth(\avSnd, [\out, 0]);

		//--main loop
		u.drawFunc= {
			trk.set(\sample, ~scopeGUI.options.sample);
			//Pen.alpha = 0.25;
			Pen.width = 5;
			Pen.fillColor= Color.grey(0, ~scopeGUI.options.trails);
			Pen.fillRect(u.bounds);		//manually clear
			Pen.strokeColor= Color.white;
			switch(~scopeGUI.options.version,
				0, {			//line
					Pen.rotate(theta, width/2, height/2);
					Pen.translate(0, height*0.5);
					arr.do{|y, x|
						var p= Point(x, y*(height*~scopeGUI.options.amp));
						if(x==0, {Pen.moveTo(p)}, {Pen.lineTo(p)});
					};
					Pen.stroke;
				},
				1, {			//warp
					Pen.rotate(theta, width/2, height/2);
					Pen.translate(width*0.5, height*0.5);
					arr.do{|y, x|
						var p= Point(x*~scopeGUI.options.amp, y*~scopeGUI.options.amp).rotate(y*2pi);
						if(x==0, {Pen.moveTo(p)}, {Pen.lineTo(p)});
					};
					Pen.stroke;
				},
				2, {			//flower
					Pen.translate(width*0.5, height*0.5);
					Pen.moveTo(Point(arr[0], 0)*arr[0]);
					arr.do{|y, x|
						var p= Point(y, x)*y;
						var a= x%width/width*2pi+theta;
						Pen.lineTo(p.rotate(a));
					};
					Pen.stroke;
				}
			);
			theta= theta+~scopeGUI.options.speed;
		};

		//--window management
		u.clearOnRefresh= false;	//do not erase - just draw on top of
		w.onClose= {
			snd.free;
			trk.free;
			o.free;
		};
		// w.front;
		CmdPeriod.doOnce({if(w.isClosed.not, {w.close})});
		~scopeGUI.win = w;
	};
	~scopeGUI.startGui;
};