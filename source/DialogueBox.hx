package;

import flixel.util.FlxDestroyUtil;
import flixel.tweens.FlxTween;
import flixel.sound.FlxSound;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.FlxG;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxSpriteGroup;
import haxe.Constraints.Function;
import flixel.FlxSprite;

class DialogueBox extends FlxSpriteGroup {
	var curLine:Int = -1;
	var port:FlxSprite;
	var finishCB:Function;
	var dialogueJSON:DialogueFile;
	var box:FlxSprite;
	var text:FlxTypeText;
	var bitmap:FlxBitmapText;
	var sound:FlxSound;

	public function new(dialogueJSON:DialogueFile, finishCB:Function) {
		super();
		this.finishCB = finishCB;
		this.dialogueJSON = dialogueJSON;

        alpha = 0;
        FlxTween.tween(this,{alpha:1},0.5);

		sound = new FlxSound();
		sound.loadEmbedded(Paths.music('Lunchbox'), true);
		sound.play();
		FlxG.sound.list.add(sound);
		port = new FlxSprite();
		box = new FlxSprite(-20, 45);

		box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-pixel');
		box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
		box.animation.addByIndices('normal', 'Text Box Appear instance 1', [4], '', 24);

		box.animation.play('normalOpen');
		box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		box.updateHitbox();
		add(box);

		box.screenCenter(X);
		text = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), '', 32);
        
        text.sounds = [new FlxSound().loadEmbedded(Paths.sound("pixelText"))];
		text.start(0.03, true);

		add(text);
		nextDialog();
	
	}

	function nextDialog():Void {
		curLine++;
        if(curLine > dialogueJSON.dialogue.length - 1)
        {
         FlxTween.tween(this,{alpha:0},1,{onComplete: end});
           
            return;
        }

		text.resetText(dialogueJSON.dialogue[curLine].text);
        text.color = 0x4E1010;
        text.start(0.03,true);
	}
    function end(?e) {
        kill();
        for (index => value in members) {
            value.destroy();
            remove(value,true);
        }
        finishCB();
        destroy();
      
        FlxG.state.remove(this,true);
    }
    override  function destroy() {
        FlxG.sound.list.remove(sound,true);
        finishCB = null;
        text = FlxDestroyUtil.destroy(text);
        sound = FlxDestroyUtil.destroy(sound);
        box = FlxDestroyUtil.destroy(box);
        super.destroy();
    }

	override function update(elapsed:Float) {
	
		super.update(elapsed);
        if(PlayState.instance.controls.ACCEPT && !(curLine > dialogueJSON.dialogue.length - 1))
        {
            nextDialog();
        }
	}
}

typedef DialogueFile = {
	var dialogue:Array<DialogueLine>;
}

typedef DialogueLine = {
	var portrait:Null<String>;
	var text:Null<String>;
}
