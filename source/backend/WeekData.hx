package backend;

import haxe.PosInfos;
import openfl.Assets;
import haxe.Json;

class WeekData {
	public static var weeks:Map<String, WeekFile> = new Map<String, WeekFile>();

	public static function init() {
		var weekFiles:Array<String> = FileUtil.readDirectory("assets/weeks/", 2);
		for (i in 0...weekFiles.length) {
			var weekPath:String = weekFiles[i].split(".json")[0];
			try {
				var weekFile:WeekFile = parseWeek(weekPath);
				trace('Week "$weekPath" succesfully  parsed and Loaded.');
				weeks[weekPath] = weekFile;
				for (i in 0...weeks[weekPath].difficulties.length) {
					var diff:String = weeks[weekPath].difficulties[i];
					if (!Difficulty.diffs.contains(diff))
						Difficulty.diffs.push(diff);
				}
			} catch (e:Dynamic) {
				var errMSG:String = 'Week "$weekPath" could not be parsed. \nError Info: $e';
			}
		}
	}

	/** 
	 * this also is called by PolymodHandler lol ------------------
	 * calls init  but it actually clears the week cache it does so no dupes ahjjjj (also shuts off traces til its done :3)
	**/
	public static function reload() {
		var oldTrace = haxe.Log.trace;
		haxe.Log.trace = function(val:Dynamic, ?pos:PosInfos) {};
		weeks.clear();
		for (i in 0...Difficulty.diffs.length)
			Difficulty.diffs.pop();
		init();
		haxe.Log.trace = oldTrace;
		oldTrace = null;
	}

	public static function parseWeek(weekName:String):WeekFile {
		return cast Json.parse(Assets.getText(Paths.week(weekName)));
	}
}
