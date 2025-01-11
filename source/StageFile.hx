package;

typedef StageFile = {
	public var bfOffsets:Null<Array<Float>>;
	public var gfOffsets:Null<Array<Float>>;
	public var dadOffsets:Array<Float>;

	public var cam_dad:Null<Array<Float>>;
	public var cam_bf:Null<Array<Float>>;
	public var cam_gf:Null<Array<Float>>;

	public var isPixel:Null<Bool>;
	public var camSPEED:Null<Float>;

	public var defaultCamZoom:Null<Float>;
}
@:publicFields
class StageUtil {
	static function vanillaGF(s:String):String {
		switch (s) {
			case "school":
				return "gf-pixel";
			case "schoolEvil":
				return "gf-pixel";
			case 'mall':
				return 'gf-christmas';
			case 'mallEvil':
				return 'gf-christmas';
			case 'spooky':
				return 'gf';
			case 'philly':
				return 'gf';
			case 'limo':
				return 'gf-car';
			case 'tank':
				return 'gf-tankman';
			case 'stage':
				return 'gf';
		}
		return 'gf';
	}

	public static function vanillaSongStage(songName):String {
		switch (songName) {
			case 'spookeez' | 'south' | 'monster':
				return 'spooky';
			case 'pico' | 'blammed' | 'philly' | 'philly-nice':
				return 'philly';
			case 'milf' | 'satin-panties' | 'high':
				return 'limo';
			case 'cocoa' | 'eggnog':
				return 'mall';
			case 'winter-horrorland':
				return 'mallEvil';
			case 'senpai' | 'roses':
				return 'school';
			case 'thorns':
				return 'schoolEvil';
			case 'ugh' | 'guns' | 'stress':
				return 'tank';
		}
		return 'stage';
	}

}
