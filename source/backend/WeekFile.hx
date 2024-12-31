package backend;

typedef WeekFile = {
	var weekImage:String;
	var displayText:String;
	var weekBefore:String;

	var startsUnlocked:Bool;
	var order:Int;
	var difficulties:Array<String>;
	var songs:Array<WSongMeta>;
}

typedef WSongMeta = {
	var name:String;
	var freeplayIcon:String;
	var color:RGBColor;
}

typedef RGBColor = Array<Int>;
