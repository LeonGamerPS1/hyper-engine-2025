package modding;
import backend.WeekData;
import firetongue.FireTongue;
import polymod.Polymod;
import polymod.format.ParseRules.TextFileFormat;
import polymod.fs.ZipFileSystem;

class PolymodHandler {
	static final MOD_FOLDER:String =
		#if (REDIRECT_ASSETS_FOLDER && macos)
		'../../../../../../../example_mods'
		#elseif REDIRECT_ASSETS_FOLDER
		'../../../../example_mods'
		#else
		'mods'
		#end;

	static final CORE_FOLDER:Null<String> =
		#if (REDIRECT_ASSETS_FOLDER && macos)
		'../../../../../../../assets'
		#elseif REDIRECT_ASSETS_FOLDER
		'../../../../assets'
		#else
		null
		#end;

	public static var loadedModIds:Array<String> = [];

	// Use SysZipFileSystem on desktop and MemoryZipFilesystem on web.
	static var modFileSystem:Null<ZipFileSystem> = null;

	public static function init(?framework:Null<Framework>) {
		#if sys // fix for crash on sys platforms 
		if(!sys.FileSystem.exists('./mods'))
			sys.FileSystem.createDirectory('./mods');
		#end
		var dirs:Array<String> = [];
		var polyMods = Polymod.scan({modRoot: './mods/'});
		for (i in 0...polyMods.length) {
			var value = polyMods[i];
			dirs.push(value.modPath.split("./mods/")[1]);
			loadedModIds.push(value.id);
		}
		framework ??= FLIXEL;

		var tongue:FireTongue = new FireTongue();
		tongue.init("en-US");

		Polymod.init({
			framework: FLIXEL,
			modRoot: "./mods/",
			dirs: dirs,
			parseRules: buildParseRules(),
			errorCallback: PolymodErrorHandler.error,
			firetongue: tongue
		});
		forceReloadAssets();
	}

	public static function createModRoot():Void {
		FileUtil.createDirIfNotExists(MOD_FOLDER);
	}

	static function buildParseRules():polymod.format.ParseRules {
		var output:polymod.format.ParseRules = polymod.format.ParseRules.getDefault();
		// Ensure TXT files have merge support.
		output.addType('txt', TextFileFormat.LINES);
		output.addType('json', TextFileFormat.JSON);
		// Ensure script files have merge support.
		output.addType('hscript', TextFileFormat.PLAINTEXT);
		output.addType('hxs', TextFileFormat.PLAINTEXT);
		output.addType('hxc', TextFileFormat.PLAINTEXT);
		output.addType('hx', TextFileFormat.PLAINTEXT);

		// You can specify the format of a specific file, with file extension.
		// output.addFile("data/introText.txt", TextFileFormat.LINES)
		return output;
	}

	public static function forceReloadAssets():Void {
		WeekData.reload();
		Polymod.clearScripts();
		Polymod.registerAllScriptClasses();
	}
}
