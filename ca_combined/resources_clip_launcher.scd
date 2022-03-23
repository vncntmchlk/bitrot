Pdefn(\clipSequencer, r {
	var clipSeq = Pseq([1, 0, 1, 9,1, 0], inf).asStream;
	loop{
		~toBenni.sendMsg("/clips", clipSeq.next);
		0.yield;
}});