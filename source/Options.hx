package;

import android.AndroidControls;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxCamera;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;

class Options extends MusicBeatSubState {
	private var options:Array<{label:String, key:String, value:Bool}>;
	private var selectedIndex:Int = 0;
	private var optionTexts:Array<FlxText>;
	var cam:FlxCamera = new FlxCamera();

	public static var defaultOptions:Map<String, Bool> = [
		"splashes" => false,
		"strumGlowPlr" => true,
		"strumGlowBot" => true,
		"strumGlowOpp" => false,
		"downScroll" => false,
		"cpuControlled" => false,
		"lowQuality" => false,
		"antialias" => true
		#if sys, "loading" => true, #end
	];

	override public function create():Void {
		super.create();
		FlxG.camera.alpha = 0.5;

		// Initialize options
		options = [
			{label: "Note-Splashes", key: "splashes", value: false},
			{label: "Player Strums Glow", key: "strumGlowPlr", value: true},
			{label: "Botplay Strums Glow", key: "strumGlowBot", value: true},
			{label: "Opponent Strums Glow", key: "strumGlowOpp", value: false},
			{label: "Down-Scroll", key: "downScroll", value: false},
			{label: "Botplay", key: "cpuControlled", value: false},
			{label: "Low-Quality", key: "lowQuality", value: false},
			{label: "Anti-Aliasing", key: "antialias", value: false}
			#if sys
			, {label: "Preload Assets", key: "loading", value: false},
			#end
		];

		for (option in options) {
			if (Reflect.getProperty(FlxG.save.data, option.key) == null) {
				Reflect.setProperty(FlxG.save.data, option.key, option.value);
			} else {
				option.value = Reflect.getProperty(FlxG.save.data, option.key);
			}
		}

		// Title
		var title:FlxText = new FlxText(0, 10, FlxG.width, "Options Menu");
		title.setFormat(null, 16, FlxColor.WHITE, "center");
		add(title);

		// Option texts
		optionTexts = [];
		for (i in 0...options.length) {
			var option = options[i];
			var optionText = new FlxText(0, 50 + i * 40, FlxG.width, getOptionText(option));
			optionText.setFormat(null, 12, FlxColor.GRAY, "center");
			optionTexts.push(optionText);
			add(optionText);
		}

		updateSelected(); // Highlight the initially selected option
		if (AndroidControls.isEnabled)
			add(AndroidControls.createVirtualPad(UP_DOWN, A_B));
		cameras = [cam];
		FlxG.cameras.add(cam, false);
	}

	private function getOptionText(option:{label:String, key:String, value:Bool}):String {
		return option.label + ": " + (option.value ? "ON" : "OFF");
	}

	private function updateSelected():Void {
		// Update the color of all option texts
		for (i in 0...optionTexts.length) {
			if (i == selectedIndex) {
				optionTexts[i].color = FlxColor.YELLOW; // Highlight selected
			} else {
				optionTexts[i].color = FlxColor.GRAY; // Unselected
			}
		}
	}

	private function toggleOption():Void {
		var option = options[selectedIndex];
		option.value = !option.value;
		Reflect.setProperty(FlxG.save.data, option.key, option.value);
		FlxG.save.flush();

		optionTexts[selectedIndex].text = getOptionText(option);

		// Apply changes if necessary (e.g., fullscreen toggle)
		if (option.key == "fullscreen") {
			FlxG.fullscreen = option.value;
		}
	}

	public static function CheckDefaults() {
		for (key => value in defaultOptions)
			if (Reflect.getProperty(FlxG.save.data, key) == null)
				Reflect.setProperty(FlxG.save.data, key, value);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		// Navigate up and down
		if (controls.UI_UP_P) {
			selectedIndex = (selectedIndex - 1 + options.length) % options.length; // Wrap around
			updateSelected();
			FlxG.sound.play(Paths.sound('scrollMenu'), 1, false);
		} else if (controls.UI_DOWN_P) {
			selectedIndex = (selectedIndex + 1) % options.length; // Wrap around
			updateSelected();
			FlxG.sound.play(Paths.sound('scrollMenu'), 1, false);
		}

		// Toggle selected option
		if (controls.ACCEPT) {
			toggleOption();
			FlxG.sound.play(Paths.sound('confirmMenu'), 1, false);
		}

		if (controls.BACK) {
			killMembers();
			for (index => value in members) {
				value.destroy();
				remove(value, true);
			}
			cam.kill();
			cam.destroy();
			FlxG.cameras.remove(cam, false);
			FlxG.camera.alpha = 1;

			FlxTransitionableState.skipNextTransOut = true;
			FlxTransitionableState.skipNextTransIn = true;
			FlxG.switchState(new MainMenu());
		}
	}
}
