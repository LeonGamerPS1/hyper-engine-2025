package ume.chart.format.v1;

typedef CFormat =
{
	var name:String;
	var bpm:Float;
	var notes:Array<{strumTime:Float, noteData:Int, type:String}>;
}
