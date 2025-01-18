package editors;

import openfl.Assets;
import haxe.Json;

class Events {
	public static var events:Map<String, EventData> = new Map<String, EventData>();

	public static function init() {
		var eventFiles:Array<String> = FileUtil.readDirectory("assets/events/", 2);
		for (i in 0...eventFiles.length) {
			var eventPath:String = eventFiles[i].split(".json")[0];
			try {
				var eventFile:EventData = parseevent(eventPath);
				events.set(eventFile.name, eventFile);
				
			} catch (e:Dynamic) {
				var errMSG:String = 'event "$eventPath" could not be parsed. \nError Info: $e';
			}
		}
	}

	public static function reload() {
		events.clear();
		init();
	}

	public static function parseevent(eventName:String):EventData {
		return cast Json.parse(Assets.getText(Paths.event(eventName)));
	}

	public static function makeList() {
		var array:Array<String> = [];
		for (key => value in events)
			array.push(key);

		return array;
	}
}
