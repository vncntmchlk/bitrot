// kontroloberflaeche
// sendrate
// blendSteps
// rule
// lastValuesSize


Tdef(\fftBinsGainSmooth, {
	var lastColSums = 0 ! ~game.caSize;
	var nextColSums;
	var sendRate = 2; // Hz
	var blendSteps = 10;
	var sendDb;
	var dbArr = [4, 8, 12, 16, 20, 24];
	var dbArrRev = dbArr.reverse;
	loop {
		if(blendSteps > 1){
			var waitTime = (sendRate * blendSteps).reciprocal;
			~game.nextGen(false);
			nextColSums = ~game.colSums;
			blendSteps.do { |step|
				var blendedColSums = lastColSums.blend(nextColSums, step / blendSteps);
				~game.colSums = blendedColSums;
				~game.visualize; //~game.visualize(false);
				sendDb = ~game.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, -1 * dbArrRev[ix], dbArr[ix], 1)};
				~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
				waitTime.wait;
			};
			lastColSums = nextColSums;
		}{
			~game.nextGen;
			sendDb = ~game.colSums[3..8].collect {|v, ix| v.lincurve(0, 1, -1 * dbArrRev[ix], dbArr[ix], 1)};
			~toBenni.sendMsg("/bitrotData", "fftBinsGain", *sendDb);
			sendRate.reciprocal.wait;
		}
	}
})
