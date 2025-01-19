package util;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Paths {
	public static var sound_ext(default, null):String = ".ogg";
	public static var image_ext(default, null):String = ".png";
	public static var image_xml_ext(default, null):String = ".xml";
	public static var data_ext(default, null):String = ".json";

	public static var dumpExclusions:Array<String> = [];

	public static var localTrackedAssets:Array<String> = [];
	public static var currentTrackedAssets:Map<String, Dynamic> = [];

	static var currentLevel:String;

	static public function setCurrentLevel(name:String) {
		currentLevel = name.toLowerCase();
	}

	public static function clearUnusedMemory() {
		// clear non local assets in the tracked assets list

		System.gc();
	}

	public static function clearAll() {
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	static public function getLibraryPath(file:String, library = "preload") {
		var result = if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
		if (result.contains(':'))
			result = result.split(':')[1];
		return result;
	}

	inline static function getLibraryPathForce(file:String, library:String) {
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String) {
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String) {
		var result = getPath(file, type, library);

		return result;
	}

	inline static public function txt(key:String, ?library:String) {
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function week(key:String, ?library:String) {
		return getPath('weeks/$key.json', TEXT, library);
	}

	inline static public function event(key:String, ?library:String) {
		return getPath('events/$key.json', TEXT, library);
	}

	inline static public function video(key:String, ?library:String) {
		return getPath('videos/$key.mp4', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String) {
		return getPath('images/$key.xml', TEXT, library);
	}

	inline static public function voices(key:String) {
		key = key.toLowerCase();
		return getPath('songs/$key/Voices.ogg', SOUND);
	}

	inline static public function audioStream(key:String) {
		var vorbis = VorbisFile.fromFile(key);

		var buffer = AudioBuffer.fromVorbisFile(vorbis);
		return Sound.fromAudioBuffer(buffer);
	}

	inline static public function inst(key:String) {
		key = key.toLowerCase();
		return getPath('songs/$key/Inst.ogg', SOUND);
	}

	inline static public function json(key:String, ?library:String) {
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String) {
		return getPath('sounds/$key$sound_ext', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String) {
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String) {
		return getPath('music/$key$sound_ext', MUSIC, library);
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String>) {
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null) {
			var levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	public static inline function getText(path:String):String {
		return openfl.utils.Assets.getText(path);
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null) {
		return (Assets.exists(getPath(key, type, parentFolder)));
	}

	static public function img(key:String, ?library:String):String {
		var file:String = "";

		file = getPath('images/$key.png', IMAGE, library);
		return file;
	}

	static public function image(key:String, ?library:String, ?allowGPU:Bool = true) {
		return img(key, library != null ? library : null);
	}

	public static inline function getSparrowAtlas(key:String) {
		return FlxAtlasFrames.fromSparrow(image('$key'), xml('$key'));
	}

	inline static public function getPackerAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames {
		var imageLoaded = image(key, library, allowGPU);

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath('images/$key.txt', TEXT));
	}

	public static inline function getFlxAnimatePath(key:String) {
		return getPath('images/$key', TEXT);
	}

	inline static public function newsvoices(key:String, variation:String = "") {
		key = key.toLowerCase();
		return getPath('songs/$key/Voices${variation != "" ? '-$variation' : ""}.ogg', SOUND);
	}

	#if sys
	public static inline function getBytes(path:String):haxe.io.Bytes {
		return sys.io.File.getBytes(path);
	}
	#end

	public static function shaderFrag(key:String) {
		return getPath('shaders/$key.frag', TEXT);
	}

	public static function formatSongName(s:String):String {
		return s.toLowerCase().replace(" ", "-");
	}
}
