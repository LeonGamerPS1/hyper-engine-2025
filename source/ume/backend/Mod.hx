package ume.backend;

import flixel.util.FlxColor;
import ume.chart.format.v1.Legacy.SwagSong;

@:publicFields @:structInit class Mod
{
	var name:String;

	var description:String;
	var version:String;
	var color:FlxColor;
	var global:Bool;
	var modSysVer:Float;
	var ID:Int;
	var iconPath:String;

	// var awards:Array<Award>;


	// var events:Array<Event>;
	// var notes:Array<CustomNote>;
	// var scripts:Array<String>;
	var songs:Array<SwagSong>;
	var weeks:Array<Week>;
	var path:String;
	var folder:String;
}

typedef ModJSON =
{
	var name:Null<String>;
	var description:Null<String>;
	var version:Null<String>;
	var color:Array<Int>;
	var global:Null<Bool>;
	var modSysVer:Null<Float>;
}
