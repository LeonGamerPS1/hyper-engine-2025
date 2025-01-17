package editors;

import flixel.addons.ui.FlxUIButton;
import flixel.FlxG;

class NoteRGBEditorState extends MusicBeatState
{
	public var strums:StrumLine;

	override function create()
	{
		super.create();
		strums = new StrumLine(FlxG.width / 2 - Note.swagWidth * Receptor.strumScale, FlxG.height / 2, false);
		strums.screenCenter();
		strums.x -= 100;
		add(strums);

		var btn:FlxUIButton = new FlxUIButton(strums.x - 300, strums.y, "Swap Pixel-Note", function()
		{
			for (i in 0...4)
			{
				var strum = strums.getReceptorOfID(i);
				strum.isPixel = !strum.isPixel;
				strum.reloadNote();
				strums.screenCenter();
				strums.x -= 100;
			}
		});
		add(btn);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (controls.BACK)
			FlxG.switchState(new OptionsMenu());
		keyFUCK();
	}
	function keyFUCK() {
		var holdArray:Array<Bool> = [controls.NOTE_LEFT,controls.NOTE_DOWN,controls.NOTE_UP,controls.NOTE_RIGHT];
		for (i in 0...holdArray.length) {
			if(holdArray[i])
				strums.getReceptorOfID(i).playAnim("confirm");
			else 
				strums.getReceptorOfID(i).playAnim("static",true);
		}
	}
	
}
