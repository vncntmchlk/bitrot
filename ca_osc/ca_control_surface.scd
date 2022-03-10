// kontroloberflaeche

"ca_resources_osc.scd".loadRelative;
~toBenni = NetAddr("10.42.0.171", 7401);

~game = ~ca.(12, 10)

~game.nextGen
/*~game[\newLastValuesSize].(10)
~game[\newCaSize].(8)*/


Tdef(\fftBinsGainSmooth, {
	var lastColSums = 0 ! ~sharedEv.caSize;
	var nextColSums;
	var sendDb;
	var dbArr = [
		[-9, 9],
		[-6, 12],
		[-3, 15],
		[0, 18],
		[0, 21],
		[0, 24]
	];
	loop {
		var blendSteps = ~sharedEv.blendSteps;
		var sendRate = ~sharedEv.sendRate; // Hz
		if(~sharedEv.blendSteps > 1){
			var waitTime = (~sharedEv.sendRate * blendSteps).reciprocal;
			~game.nextGen(false);
			nextColSums = ~game.colSums;
			blendSteps.do { |step|
				var blendedColSums = lastColSums.blend(nextColSums, step / blendSteps);
				~game.colSums = blendedColSums;
				~game.visualize; //~game.visualize(false);
				sendDb = ~game.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, dbArr[ix][0], dbArr[ix][1], -4)};
				~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
				waitTime.wait;
			};
			lastColSums = nextColSums;
		}{
			~game.nextGen;
			sendDb = ~game.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, dbArr[ix][0], dbArr[ix][1], -4)};
			~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
			sendRate.reciprocal.wait;
		}
	}
})
Tdef(\fftBinsGainSmooth).play