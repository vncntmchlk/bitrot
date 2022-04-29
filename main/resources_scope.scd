
~scopeGUI = ();
~scopeGUI.winSize = 800; //global window size
~scopeGUI.buffer = Buffer.alloc(s, ~scopeGUI.winSize, 1);
~scopeGUI.options = ();
SynthDef(\avTrk, {|bufnum, rate= 40, sample= 1|
	var z = SoundIn.ar(~guiInputBus); //In.ar(in, 1);
	var trig= Impulse.ar(rate*0.92);	//compensate
	var index= Phasor.ar(trig, sample, 0, BufFrames.ir(bufnum)-1);
	BufWr.ar(z, bufnum, index, 0);
	SendTrig.ar(trig, 0, bufnum);
	0
}).add;
/*SynthDef(\avSnd, {|out= 0, bufnum|
	Out.ar(out, SoundIn.ar([~guiInputBus, ~guiInputBus + 1]))
}).add;*/
s.sync;
//--interface
~scopeGUI.options.trails= 1;
~scopeGUI.options.speed= 0;
~scopeGUI.options.sample= 1;
~scopeGUI.options.amp= 0.5;
~scopeGUI.options.version= 0;
~scopeGUI.options.penWidth = 5;
~scopeGUI.options.penColor = Color.white;

~scopeGUI.onOff = { |onOff|
	onOff = onOff.asBoolean;
	~scopeGUI.trk.run(onOff);
	//~scopeGUI.snd.run(onOff);
	{~scopeGUI.win.visible_(onOff)}.defer
};

~scopeGUI.startGui = {
	//--setup
	var width= ~scopeGUI.winSize, height= ~scopeGUI.winSize;
	var w= Window("scope", Rect(99, 99, width, height),false,~guiBorder)
	.background_(Color.grey(0,0));//.autoRememberPosition(\bitrot, \scopeGUI);
	var u= UserView(w, Rect(0, 0, width, height));

	//--variables
	var theta= 0;
	var initFps= 60;
	var arr= Array.fill(~scopeGUI.winSize, 0);		//same as half windowsize above
	var o= OSCFunc({|m|
		if(m[2]==0, {			//redraw once for each cycle of amps
			~scopeGUI.buffer.getn(0, ~scopeGUI.winSize-1, {|data| {arr= data; u.refresh}.defer});
		});
	}, '/tr', s.addr);
	~scopeGUI.trk = Synth.newPaused(\avTrk, [\bufnum, ~scopeGUI.buffer, \rate, initFps]);
	//~scopeGUI.snd = Synth.newPaused(\avSnd, [\out, 0]);

	//--main loop
	u.drawFunc= {
		~scopeGUI.trk.set(\sample, ~scopeGUI.options.sample);
		//Pen.alpha = 0.25;
		Pen.width = ~scopeGUI.options.penWidth;
		if(~scopeGUI.options.trails < 1){
			u.clearOnRefresh = false;
			Pen.fillColor = Color.grey(0, ~scopeGUI.options.trails);
		}{
			u.clearOnRefresh = true;
			Pen.fillColor = ~guiBackgroundColor;//Color.grey(0, ~scopeGUI.options.trails);
		};

		Pen.fillRect(u.bounds);		//manually clear
		Pen.strokeColor= ~scopeGUI.options.penColor;
		switch(~scopeGUI.options.version,
			0, {			//line
				//Pen.rotate(theta, width/2, height/2);
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
				Pen.scale(~scopeGUI.options.amp, ~scopeGUI.options.amp);
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
	//u.clearOnRefresh= false;	//do not erase - just draw on top of
	u.clearOnRefresh = true;
	w.onClose= {
		//~scopeGUI.snd.free;
		~scopeGUI.trk.free;
		o.free;
	};
	CmdPeriod.doOnce({if(w.isClosed.not, {w.close})});
	~scopeGUI.win = w;
};
~scopeGUI.startGui;

