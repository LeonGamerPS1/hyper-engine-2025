package ume.chart.format.v1;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import ume.assets.UMEAssets;

using StringTools;
#if sys
import sys.FileSystem;
#end

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var player3:String;
	var validScore:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var player3:String = 'gf';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson:String = new String("");

		#if MODS_ALLOWED
		if (FileSystem.exists(UMEAssets.modsJson(folder.toLowerCase() + '/' + jsonInput.toLowerCase())))
			rawJson = sys.io.File.getContent(UMEAssets.modsJson(folder.toLowerCase() + '/' + jsonInput.toLowerCase())).trim();
		else
			rawJson = Assets.getText(UMEAssets.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase())).trim();
		#else
		rawJson = Assets.getText(UMEAssets.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase())).trim();
		#end

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		return parseJSONshit(rawJson);
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}
}
