package display;

import openfl.display.Graphics;
import openfl.display.Sprite;
import flixel.math.FlxMath;
import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import haxe.Int64;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
class DebugDisplay extends TextField {
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this IS your total program memory usage)
	**/
	public var memoryMegas(get, never):String;

	public var gcMemory(get, never):String;
    var _gfx:Graphics;

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000) {
		super();

		this.x = x;
		this.y = y;
        

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("Monsterrat", 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";
       
		
       

		times = [];
	}

	var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void {
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000)
			times.shift();
		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 50) {
			deltaTimeout += deltaTime;
			return;
		}

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();
		deltaTimeout = 0.0;
	}

	public function updateText():Void {
		text = 'FPS: ${currentFPS}' + '\n${memoryMegas} | GC ${gcMemory}';
		text += LibraryInfo.librarys;
	}

	static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

	public static function getInterval(size:Float) {
		var data:Int = 0;
		while (size > 1024 && data < intervalArray.length - 1) {
			data++;
			size = (size / 1024);
		}

		final truncatedSize:Float = FlxMath.roundDecimal(size, 1);

		return '$truncatedSize ${intervalArray[data]}';
	}

	/**
	 * Method which outputs a formatted string displaying the current memory usage.
	 * @return String
	 */
	inline function get_memoryMegas():String {
		final memory:Float = MemoryUtil.getMemoryfromProcess();
		return 'Memory Usage : ${getInterval(memory)}';
	}

	inline function get_gcMemory():String {
		final memory:Float = MemoryUtil.getGCMem();
		return '${getInterval(memory)}';
	}
}
