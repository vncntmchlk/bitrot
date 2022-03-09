// fftBinsGain und ffsBinsDenoise durch CAs steuern

"ca_resources.scd".loadRelative; // ~ca
~toBenni = NetAddr("10.42.0.171", 7401);
~toBenni.sendMsg("/bitrotData", "groupTrunc", 0.5) // 0 - 1 bittiefe
~toBenni.sendMsg("/bitrotData", "fftXbins", *[16, 32, 64, 128, 256]) // bins

~toBenni.sendMsg("/bitrotData", "fftXbins", *[2, 4, 8, 16, 32]) // bins
~toBenni.sendMsg("/bitrotData", "fftBinsDenoise", *(0!6)) // -100 bis 100 amp cutoff fuer jeweiliges Band
~toBenni.sendMsg("/bitrotData", "fftBinsGain", *(0!6)) // -100 bis 100 amp cutoff fuer jeweiliges Band

~toBenni.sendMsg("/bitrotData", "fftBinsDenoise", *(-99!6)) // -100 bis 100 amp cutoff fuer jeweiliges Band

// neues CA starten
~game.nextGen;
~game.seedMe
~game = ~ca.(12, 10);
// dieser parameter sollte wahrscheinlich von den note onsets entkoppelt bleiben?
Tdef(\fftBinsGain, {
	loop {
		var sendBinsMin, sendDb;
		var minArr = [10, 5, 2.5, 1.25, 0.75, 0.375] * 0.5;
		var dbArr = [3, 6, 9, 12, 18, 21];
		~game.nextGen;
		// da fftBinsGain 6er array erwartet nur einen ausschnit aus der mitte vom game senden
		// ~toBenni.sendMsg("/bitrotData", "fftBinsDenoise", *(~game.colSums[0].linlin(0.1, 0.9, 0, 20)!3 ++ (~game.colSums[1].linlin(0.1, 0.9, 0, 20)!3)));
		sendBinsMin = ~game.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, 0, minArr[ix],-3)};
		sendDb =~game.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, 0, dbArr[ix], 1)};
		~toBenni.sendMsg("/bitrotData", "fftBinsMin", *sendBinsMin);
		~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
		(1/8).wait;
	}
})
Tdef(\fftBinsGain).play


// modulations moeglichkeiten der CAs
~game.makeRules(30)

~game.makeRules(86)
~game.makeRules(6)
~game.makeRules(121)


~game.newCaSize(9)
~game.newLastValuesSize(2)

~game.onlyShow(5)

~fressen = 1
Tdef(\xorBits, {
	loop {
		var arr = 0!10;
		~game.nextGen;
		arr = arr[0..(9-~fressen)] ++ ~game.lastValues[0][(9-~fressen)..9];
		arr.postln;
		~toBenni.sendMsg("/bitrotData", *(["xorBits"] ++ (arr)));
		(1/8).wait;
	}
})

Tdef(\xorBits).play

~toBenni.sendMsg("/bitrotData", *(["xorBits"] ++ ([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))) // 10 bit array bitflips



Tdef(\fftBinsGainSmooth, {
	var lastColSums = 0 ! ~game.caSize;
	var nextColSums;
	var blendSteps = 10;
	var sendBinsMin, sendDb;
	var minArr = [10, 5, 2.5, 1.25, 0.75, 0.375] * 0.5;
	var dbArr = [4, 8, 12, 16, 20, 24];
	loop {
		~game.nextGen(false);
		nextColSums = ~game.colSums;
		blendSteps.do { |step|
			var blendedColSums = lastColSums.blend(nextColSums, step / blendSteps);
			~game.colSums = blendedColSums;
			~game.visualize; //~game.visualize(false);
			// send
			//sendBinsMin = ~game.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, 0, minArr[ix],-3)};
			sendDb =~game.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, -1 * dbArr.reverse[ix], dbArr[ix], 1)};
			~toBenni.sendMsg("/bitrotData", "fftBinsMin", *sendBinsMin);
			~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
			//
			(1/20).wait;
		};
		lastColSums = nextColSums;
	}
})

Tdef(\fftBinsGainSmooth).play

r = Routine({
	var lastColSums = 0 ! ~game.caSize;
	var nextColSums;
	var blendSteps = 8;
	loop {
		~game.nextGen(false);
		nextColSums = ~game.colSums;
		blendSteps.do { |step|
			var blendedColSums = lastColSums.blend(nextColSums, step / blendSteps);
			~game.colSums = blendedColSums;
			~game.visualize(false);
			0.1.wait;
		};
		lastColSums = nextColSums;
	}
}).play

