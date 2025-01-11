package;

import flixel.addons.transition.FlxTransitionableState;
import backend.DiscordClient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class Title extends MusicBeatState {
	public var fatRamEater:FlxSprite;
	public var titleText:FlxSprite;
	public var logoBl:FlxSprite;
	public var fuckingtomain:Bool = false;

	public var Note:Note = new Note();
	public var sustain:Sustain;
	public var strumTime:Float = 100;
	public var receptor:Receptor;

	public override function create() {
		FlxTransitionableState.skipNextTransIn = true;
		DiscordClient.changePresence("Title Screen");
		Conductor.changeBPM(102);
		FlxG.sound.playMusic(Paths.sound('freakyMenu'));

		fatRamEater = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		fatRamEater.frames = Paths.getSparrowAtlas('title/gfDanceTitle');
		fatRamEater.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		fatRamEater.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		fatRamEater.antialiasing = true;
		fatRamEater.animation.play('danceRight');
		add(fatRamEater);

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('title/titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = true;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		logoBl = new FlxSprite(-150, -100);
		logoBl.frames = Paths.getSparrowAtlas('title/logoBumpin');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		add(logoBl);

		super.create();
		FlxG.camera.flash();

		receptor = new Receptor(0);
		add(receptor);
		receptor.x += receptor.width / 2;
		Note.targetReceptor = receptor;
		Note.x = receptor.x;
		Note.isPixel = true;
		add(Note);
		Note.y  = receptor.y + 200;
		//PlayState.SONG = Song.loadFromJson('tutorial', 'tutorial');
		sustain = new Sustain(Note);
		add(sustain);
	}

	public var danceLeft(get, null):Bool;

	function get_danceLeft():Bool {
		return (curBeat % 2 == 0);
	}

	override function beatHit() {
		super.beatHit();
		logoBl.animation.play('bump', true);

		if (danceLeft)
			fatRamEater.animation.play('danceLeft', true);
		else
			fatRamEater.animation.play('danceRight', true);
	}

	override function update(elapsed:Float) {
		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);
		var pressedEnter:Bool = (controls.ACCEPT || tappedScreen());
		if (pressedEnter && !fuckingtomain) {
			fuckingtomain = true;
			yay();
		}
	}

	function tappedScreen() {
		#if mobile
		var touch = FlxG.touches.getFirst();
		if (touch != null)
			return touch.justPressed;
		else
			return false;
		#else
		return false;
		#end
	}

	function yay() {
		FlxG.camera.flash(FlxColor.WHITE, 1, null, true);
		FlxG.sound.play(Paths.sound('confirmMenu'), 1);
		titleText.animation.play('press');
		new FlxTimer().start(1, function(tmr:FlxTimer) {
			tmr.cancel();
			if (tmr != null)
				tmr.destroy();
			FlxG.switchState(new MainMenu());
		});
	}
}
