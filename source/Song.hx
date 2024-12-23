package;

import haxe.Json;
import lime.utils.Assets;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Int;
	var sections:Int;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;

	
	var gfVersion:String;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Int;
	public var sections:Int;
	public var sectionLengths:Array<Dynamic> = [];
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public function new(song, notes, bpm, sections)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
		this.sections = sections;

		for (i in 0...notes.length)
		{
			this.sectionLengths.push(notes[i]);
		}
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = Assets.getText('assets/data/' + folder.toLowerCase() + '/' + jsonInput.toLowerCase() + '.json').trim();

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var swagShit:SwagSong = cast Json.parse(rawJson).song;

		swagShit.player1 ??= "bf";
		swagShit.player2 ??= "dad";
		swagShit.gfVersion ??= "gf";

		return swagShit;
	}
}
