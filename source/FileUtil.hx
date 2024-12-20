package;

import lime.utils.Assets;

using StringTools;

class FileUtil {
	public static function createDirIfNotExists(dir:String):Void {
		#if sys
		if (!doesFileExist(dir)) {
			sys.FileSystem.createDirectory(dir);
		}
		#end
	}

	public static function doesFileExist(path:String):Bool {
		#if sys
		return sys.FileSystem.exists(path);
		#else
		return false;
		#end
	}

	// thank you jake <3

	/**
	 * A Wack Ass Attempt At A Polymod Safe `FileSystem.readDirectory`
	 * @param path 
	 * @return Array<String>
	 */
	public static function readDirectory(path:String, index:Int = 0):Array<String> {
		final lib = Assets.getLibrary('default');
		final list:Array<String> = lib.list(null);
		var stringList:Array<String> = [];
		for (hmm in list) {
			if (hmm.startsWith(path)) {
				final bruh:String = hmm.split('/')[index];

				if (stringList.contains(bruh))
					continue;

				stringList.push(bruh);
			}
		}

		stringList.sort(Reflect.compare);
		return stringList;
	}
}
