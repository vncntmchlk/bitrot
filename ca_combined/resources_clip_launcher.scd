Pdefn(\clipSequencer, r {
	var clipSeq = Pseq([1, 0, 1, 9,1, 0], inf).asStream;
	loop{
		~toBenni.sendMsg("/clips", clipSeq.next);
		0.yield;
}});

Pdefn(\clipSequencer, r {
	var clipSeq = Pwrand([5,2,1],[0.8,0.1,0.1], inf).asStream;
	loop{
		~toBenni.sendMsg("/clips", clipSeq.next);
		0.yield;
}});

Pdefn(\clipSequencer, r {
	var clipSeq = Pwrand([0,2,1],[0.8,0.1,0.1], inf).asStream;
	loop{
		~toBenni.sendMsg("/clips", clipSeq.next);
		0.yield;
}});
