package modding;

import haxe.Json;
import lime.utils.Assets;

using StringTools;

typedef SwagSong = {
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;

	var stage:String;
	var version:Null<String>;
}

typedef SwagEvent = {
	var name:String;
	var time:Float;

	
	@:optional var val1:String;
	@:optional var val2:String;
}

class Song {
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Int;
	public var sections:Int;
	public var sectionLengths:Array<Dynamic> = [];
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public static var cache:Map<String, SwagSong> = new Map();

	public function new(song, notes, bpm, sections) {
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
		this.sections = sections;

		for (i in 0...notes.length) {
			this.sectionLengths.push(notes[i]);
		}
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong {
		var key:String = jsonInput + '-$folder';
		if (cache.exists(key))
			return cache.get(key);

		var rawJson = Assets.getText('assets/data/' + folder.toLowerCase() + '/' + jsonInput.toLowerCase() + '.json').trim();

		while (!rawJson.endsWith("}")) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var returnval = parseJSONshit(rawJson);

		Log.info('"$key" does not exist in Song Cache. Adding it to the cache shortly...');
		cache.set(key, returnval);
		return returnval;
	}

	public static function parseJSONshit(rawJson:String):SwagSong {
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.player1 ??= "bf";
		swagShit.player2 ??= "dad";
		if (swagShit.version == null)
			swagShit.version = "v0.2.1";

		return swagShit;
	}
}
