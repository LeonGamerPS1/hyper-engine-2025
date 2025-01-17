package states;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.effects.FlxFlicker;
import android.AndroidControls;
import flixel.FlxG;

class OptionsMenu extends MusicBeatState {
	private var options:Array<{label:String}>;
	private var selectedIndex:Int = 0;
	private var optionTexts:FlxTypedGroup<Alphabet> = new FlxTypedGroup();

	override public function create():Void {
		super.create();

		// Initialize options
		options = [{label: "Note-RGB"}, {label: "Options"}];

		// Title

		// Option texts
	
		for (i in 0...options.length) {
			var option = options[i];
			var optionText = new Alphabet(0, 100 * i, option.label,true);
            optionText.y += 100;
			optionText.screenCenter(X);
			optionTexts.add(optionText);
		}
        add(optionTexts);

		//updateSelected(); // Highlight the initially selected option
		if (AndroidControls.isEnabled)
			add(AndroidControls.createVirtualPad(UP_DOWN, A_B));
	}

	private function updateSelected():Void {
		for (i in 0...optionTexts.length)
			if (i == selectedIndex)
				optionTexts.members[i].alpha = 1;
			else
				optionTexts.members[i].alpha = 0.7;
	}

	private function confirmChoice():Void {
		selec = true;
		for (i in 0...optionTexts.length) {
			if (i == selectedIndex) {
				FlxFlicker.flicker(optionTexts.members[i], 1, 0.1, true, true, function(flr) {
					switch (optionTexts.members[i].text.toLowerCase()) {
						case "note-rgb":
							FlxG.switchState(new editors.NoteRGBEditorState());
						case "options":
							FlxG.switchState(new Options());
					}
				});
			}
		}
	}

	var selec = false;

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
		if (controls.ACCEPT && !selec) {
			confirmChoice();
			FlxG.sound.play(Paths.sound('confirmMenu'), 1, false);
		}

		if (controls.BACK) {
			

			FlxG.switchState(new MainMenu());
		}
	}
}
