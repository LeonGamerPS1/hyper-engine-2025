package states;

import objects.DialogueBox.DialogueFile;
import haxe.Constraints.Function;
import flixel.text.FlxText;
import flixel.graphics.frames.FlxBitmapFont;
import lime.app.Application;
import haxe.io.Path;
import flixel.FlxSubState;
import android.AndroidControls;
import editors.CharacterEditorState;
import haxe.Json;
import openfl.Assets;
import flixel.math.FlxPoint;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import backend.DiscordClient;
import flixel.group.FlxGroup;
import flixel.FlxCamera;
import effects.NoteSplash;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxBitmapText;
import flixel.util.FlxSort;

using StringTools;

class PlayState extends MusicBeatState {
	public static var storyDifficulty:Int = 1;

	public var notes:FlxTypedGroup<Note> = new FlxTypedGroup();
	public var songSpeed:Float = 1.1;
	public var spawnZone(get, null):Float;

	public static var SONG:SwagSong;

	public var noteKillOffset:Float = 350;
	public var downScroll(get, null):Bool;

	public var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	public var text:FlxBitmapText = new FlxBitmapText(0, 0, "");

	public var defaultCamZoom:Float = 1.0;
	public var voices:FlxSound = new FlxSound();
	public var opponentStrums:StrumLine;
	public var playerStrums:StrumLine;

	public var unspawnNotes:Array<Note> = [];
	public var generatedMusic:Bool = true;
	public var cpuControlled:Bool = false;


	public static var instance:PlayState;

	#if hxluajit
	public var scripts:Array<LuaScript> = [];
	#end
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup(2);

	public var songScore:Float = 0;
	public var totalHitNotes:Int = 0;
	public var totalNotes:Int = 0;
	public var accuracy:Float = 0;

	public var songMisses:Float = 0;
	public var yes:FlxPoint = new FlxPoint();

	private var startingSong:Bool = false;
	var startedCountdown:Bool = false;

	public var camHUD:FlxCamera = new FlxCamera();
	public var camUnderlay:FlxCamera = new FlxCamera();
	public var uiGroup:FlxGroup = new FlxGroup();

	var inCutscene:Bool = false;

	public var boyfriend:Character;
	public var gf:Character;
	public var dad:Character;
	public var curStage(default, default):String = "stage";

	public static var daPixelZoom(default, null):Float = 6.0;

	public var startedSong(default, null):Bool = false;
	public var gfSpeed:Int = 1;
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public var healthBar:Bar;
	public var health:Float = 1;
	public var curHealth:Float = 1;

	public var timeBar:Bar;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var stageJson:StageFile;

	var spawnedNote:Note = new Note();

	public var luaSprites:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	public var luaTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var luaShaders:Map<String, Shader> = new Map<String, Shader>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var amountOfRenderedNotes:Float = 0;
	public var maxRenderedNotes:Float = 0;
	public var skippedCount:Float = 0;
	public var maxSkipped:Float = 0;
	public var paused:Bool = false;
	public var songPos:Float = 0;

	public static var seenCutscene:Bool = false;

	override public function create() {
		Paths.clearUnusedMemory();
		instance = this;

		if (SONG == null)
			SONG = Song.loadFromJson('run-hard', 'run');

		parseStage();

		#if hxluajit
		var globalScripts = FileUtil.readDirectory("assets/scripts", 2).filter(function(ffe:String) {
			return ffe.contains(".lua");
		});
		var songScripts = FileUtil.readDirectory('assets/data/${SONG.song.toLowerCase().replace(" ", "-")}/', 3).filter(function(ffe:String) {
			return ffe.contains(".lua");
		});
		for (i in 0...globalScripts.length) {
			var file = "assets/scripts/" + globalScripts[i];
			var doPush:Bool = !luaFileExists(file);

			if (doPush) {
				var script:LuaScript = new LuaScript(file);
				scripts.push(script);
			}
		}
		for (i in 0...songScripts.length) {
			var file = 'assets/data/${SONG.song.toLowerCase().replace(" ", "-")}/' + songScripts[i];
			var doPush:Bool = !luaFileExists(file);

			if (doPush) {
				var script:LuaScript = new LuaScript(file);
				scripts.push(script);
			}
		}
		call("onCreate");
		#end
	

		DiscordClient.changePresence("Song: " + SONG.song);

		camUnderlay.bgColor.alpha = 0;
		FlxG.cameras.add(camUnderlay, false);
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);
		boyfriend = new Character(SONG.player1, true);
		dad = new Character(SONG.player2, false);
		gf = new Character(SONG.gfVersion, false);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);
		dadGroup.add(dad);
		boyfriendGroup.add(boyfriend);
		startCharacterPos(gf);
		startCharacterPos(dad, true);
		startCharacterPos(boyfriend);

		Conductor.changeBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);
		genSkibidi();

		uiGroup.add(grpNoteSplashes);

		// unspawnNotesCopy = unspawnNotes.copy();

		if (AndroidControls.isEnabled)
			uiGroup.add(AndroidControls.createVirtualPad(FULL, NONE));

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null) {
			camPos.x += gf.getGraphicMidpoint().x + gf.camera_position[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.camera_position[1];
		}

		camFollow = new FlxObject();
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
		yes.set(camPos.x, camPos.y);
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		// FlxG.camera.snapToTarget();

		//	FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection(0);
		FlxG.camera.focusOn(yes);

		super.create();
		openfl.system.System.gc();
		#if hxluajit
		call("onCreatePost");
		#end
		stagesFunc((s) -> s.createPost());
		add(uiGroup);
		uiGroup.cameras = [camHUD];
		healthBar.setColors(FlxColor.RED, FlxColor.LIME);

		startingSong = true;
		FlxG.sound.cache(Paths.inst(Paths.formatSongName(SONG.song)));
		FlxG.sound.cache(Paths.voices(Paths.formatSongName(SONG.song)));

		// FlxG.sound.music.loadEmbedded('assets/music/${SONG.song.toLowerCase()}/Inst.ogg');

		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		switch (Paths.formatSongName(SONG.song)) {
			case "senpai":
				startDialogue(Paths.formatSongName(SONG.song), startCountdown);
			// startCountdown();
			default:
				startCountdown();
		}
	}

	function startDialogue(song:String, finishCallback:Function) {
		if (!Assets.exists('assets/data/$song/dialogue.json')) {
			finishCallback();
			return;
		}
		inCutscene = true;
		var ds:DialogueFile = cast Json.parse(Assets.getText('assets/data/$song/dialogue.json'));
		var diabox:DialogueBox = new DialogueBox(ds, finishCallback);
		diabox.cameras = [camHUD];
		add(diabox);
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if (gfCheck && char.curCharacter.startsWith('gf')) { // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
			gf.kill();
		}
		char.x += char.position[0];
		char.y += char.position[1];
	}
	function luaFileExists(scriptName:String) {
		#if hxluajit
		var fileExists:Bool = false;

		for (i in 0...scripts.length) {
			if (scripts[i] != null && scripts[i].scriptName == scriptName)
				fileExists = true;
		}
		return fileExists;
		#end
	}

	public var camSPEED:Float = 1;

	function parseStage() {
		// path ??= "stage";
		if (SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageUtil.vanillaSongStage(Paths.formatSongName(SONG.song));
		if (SONG.stage == null || SONG.stage.length < 1)
			SONG.gfVersion = StageUtil.vanillaGF(SONG.stage);
		curStage = SONG.stage;

		if (Assets.exists('assets/stages/$curStage.json'))
			stageJson = cast Json.parse(Assets.getText('assets/stages/$curStage.json'));
		else
			stageJson = cast Json.parse(Assets.getText('assets/stages/stage.json'));
		if (stageJson.defaultCamZoom != null)
			defaultCamZoom = stageJson.defaultCamZoom;
		if (stageJson.bfOffsets != null && stageJson.bfOffsets.length > 1) {
			BF_X = stageJson.bfOffsets[0];
			BF_Y = stageJson.bfOffsets[1];
		}
		if (stageJson.dadOffsets != null && stageJson.dadOffsets.length > 1) {
			DAD_X = stageJson.dadOffsets[0];
			DAD_Y = stageJson.dadOffsets[1];
		}
		if (stageJson.gfOffsets != null && stageJson.gfOffsets.length > 1) {
			GF_X = stageJson.gfOffsets[0];
			GF_X = stageJson.gfOffsets[1];
		}
		if (stageJson.cam_bf != null && stageJson.cam_bf.length > 1)
			boyfriendCameraOffset = stageJson.cam_bf;
		if (stageJson.cam_gf != null && stageJson.cam_gf.length > 1)
			girlfriendCameraOffset = stageJson.cam_gf;
		if (stageJson.cam_dad != null && stageJson.cam_dad.length > 1)
			opponentCameraOffset = stageJson.cam_dad;
		if (stageJson.camSPEED != null)
			camSPEED = stageJson.camSPEED;

		startLuaScriptofname(curStage, "assets/stages/");

		switch curStage.toLowerCase() {
			case "stage":
				new stages.StageWeek1(this, true);
			case "school":
				new stages.School(this, true);
		}
	}

	function startLuaScriptofname(name:String = "", folder:String = "") {
		#if hxluajit
		name += ".lua";
		var doPush:Bool = !luaFileExists(Path.addTrailingSlash(folder) + name)
			&& Assets.exists(Path.addTrailingSlash(folder) + name, TEXT);
		if (doPush) {
			try {
				var doodoo:LuaScript = new LuaScript(Path.addTrailingSlash(folder) + name);
				scripts.push(doodoo);
			} catch (e) {
				Application.current.window.alert('$e', 'Error Loading Script named "$name". ');
			}
		}
		#end
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	var notesAddedCount:Int = 0;
	var notesToRemoveCount:Int = 0;
	var oppNotesToRemoveCount:Int = 0;

	public var boyfriendCameraOffset:Array<Float> = [0, 0];
	public var opponentCameraOffset:Array<Float> = [0, 0];
	public var girlfriendCameraOffset:Array<Float> = [0, 0];

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public function playerDance():Void {
		var anim:String = boyfriend.getAnimationName();
		if (boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * boyfriend.singDuration
			&& anim.startsWith('sing') && !anim.endsWith('miss'))
			boyfriend.dance();
	}

	public function characterBopper(beat:Int):Void {
		if (gf != null
			&& beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& !gf.getAnimationName().startsWith('sing')
			&& !gf.stunned)
			gf.dance();
		if (boyfriend != null
			&& beat % boyfriend.danceEveryNumBeats == 0
			&& !boyfriend.getAnimationName().startsWith('sing')
			&& !boyfriend.stunned)
			boyfriend.dance();
		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			dad.dance();
	}

	function startCountdown():Void {
		inCutscene = false;

		startedCountdown = true;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
			if (paused) {
				tmr.loops = swagCounter;
				return;
			}
			dad.dance();
			gf.dance();
			boyfriend.playAnim('idle');

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);
			introAssets.set('school', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);
			introAssets.set('schoolEvil', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			if (stageJson.isPixel == true)
				introAlts = introAssets.get('school');

			switch (swagCounter) {
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (curStage.startsWith('school'))
						ready.setGraphicSize(Std.int(ready.width * 6));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) {
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();

					if (curStage.startsWith('school'))
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) {
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();

					if (curStage.startsWith('school'))
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween) {
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	function startSong() {
		FlxG.sound.list.add(voices);
		FlxG.sound.playMusic(Paths.inst(Paths.formatSongName(SONG.song)), 1, false);
		voices.loadEmbedded(Paths.voices(Paths.formatSongName(SONG.song)));
		voices.looped = false;
		voices.play();
		FlxG.sound.music.onComplete = function() {
			voices.kill();
			voices.destroy();
			FlxG.switchState(new SongSel());
		};
		startedSong = true;
		startingSong = false;
		timeBar.bounds.max = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1});
		timeBar.rightBar.color = 0x000000;
		timeBar.leftToRight = false;

		#if hxluajit call('onSongStarted'); #end
	}

	function eventNoteEarlyTrigger(obj:Array<Dynamic>):Float {
		switch (obj[2]) {
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1, Obj2):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	override function destroy() {
		FlxG.sound.music.onComplete = null;
		FlxG.sound.music.stop();
		super.destroy();
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int {
		var earlyTime1:Float = eventNoteEarlyTrigger(Obj1);
		var earlyTime2:Float = eventNoteEarlyTrigger(Obj2);
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0] - earlyTime1, Obj2[0] - earlyTime2);
	}

	function genSkibidi() {
		opponentStrums = new StrumLine(0, !downScroll ? 50 : FlxG.height - 150, stageJson.isPixel, downScroll);
		playerStrums = new StrumLine(FlxG.width / 2 + (Note.swagWidth / 2), !downScroll ? 50 : FlxG.height - 150, stageJson.isPixel, downScroll);

		uiGroup.add(playerStrums);
		uiGroup.add(opponentStrums);
		uiGroup.add(notes);

		healthBar = new Bar(0, FlxG.height * (!downScroll ? 0.89 : 0.11), "healthBar", function() {
			return curHealth;
		}, 0, 2);

		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		uiGroup.add(healthBar);

		timeBar = new Bar(0, 40, "healthBar", function() {
			return songPos;
		}, 0, 2);
		if (downScroll)
			timeBar.y = FlxG.height - 170;

		timeBar.alpha = 0;
		timeBar.scale.set(0.5, 1);
		timeBar.screenCenter(X);
		timeBar.x -= 20;
		uiGroup.add(timeBar);

		iconP1 = new HealthIcon(boyfriend.json.health_icon, true);
		iconP1.y = healthBar.y - 75;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.json.health_icon, false);
		iconP2.y = healthBar.y - 75;
		uiGroup.add(iconP2);

		text.y = healthBar.y + 40;
		text.font = FlxBitmapFont.fromAngelCode(Paths.image("bmpfont/vcr_osd_mono_regular_14"), 'assets/images/bmpfont/vcr_osd_mono_regular_14.fnt');
		text.updateHitbox();
		text.borderStyle = OUTLINE;
		text.borderColor = FlxColor.BLACK;
		text.borderQuality = 2;
		text.borderSize = 2;
		text.text = "Score: ? // Misses: ? // Accuracy: ?";
		text.screenCenter(X);
		uiGroup.add(text);

		// FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		var sections:Array<SwagSection> = SONG.notes;

		for (section in sections) {
			for (songNotes in section.sectionNotes) {
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;
				var sussyLengy:Float = songNotes[2] is Float ? songNotes[2] : 0;
				var type:String = songNotes[3] is String && songNotes[3] != null ? songNotes[3] : "";
				// note infos n' stuff ^^

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				// fuck sustains

				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				if (daNoteData == -1)
					continue;

				var swagNote:Note = new Note(daStrumTime, daNoteData, false, oldNote, gottaHitNote, stageJson.isPixel == true ? true : false, type);
				swagNote.altNote = section.altAnim == true;
				swagNote.sustainLength = sussyLengy;
				unspawnNotes.push(swagNote);

				var sussyLength:Float = sussyLengy / Conductor.stepCrochet;

				for (susNote in 0...Std.int(sussyLength)) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet), daNoteData, true, oldNote,
						gottaHitNote, stageJson.isPixel == true ? true : false, type);
					sustainNote.altNote = section.altAnim == true;
					unspawnNotes.push(sustainNote);
					swagNote.tails.push(sustainNote);
					sustainNote.parent = swagNote;
				}
			}
		}
		unspawnNotes.sort(sortByShit);
	}

	public function moveCameraToGirlfriend() {
		camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
		camFollow.x += gf.camera_position[0] + girlfriendCameraOffset[0];
		camFollow.y += gf.camera_position[1] + girlfriendCameraOffset[1];
	}

	var cameraTwn:FlxTween;

	public function moveCameraSection(?sec:Null<Int>):Void {
		if (sec == null)
			sec = Std.int(curStep / 16);
		if (sec < 0)
			sec = 0;

		if (SONG.notes[sec] == null)
			return;

		if (gf != null && SONG.notes[sec].gfSection == true) {
			moveCameraToGirlfriend();
			#if hxluajit call('onMoveCamera', ["gf"]); #end
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);

		#if hxluajit
		if (isDad)
			call('onMoveCamera', ['dad']);
		else
			call('onMoveCamera', ['boyfriend']);
		#end
	}

	public function moveCamera(isDad:Bool) {
		if (isDad) {
			if (dad == null)
				return;
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.camera_position[0] + opponentCameraOffset[0];
			camFollow.y += dad.camera_position[1] + opponentCameraOffset[1];

			if (SONG.song.toLowerCase() == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1) {
				cameraTwn = FlxTween.tween(this, {defaultCamZoom: 0.8}, (Conductor.stepCrochet * 4 / 1000), {
					ease: FlxEase.linear,
					onComplete: function(twn:FlxTween) {
						cameraTwn = null;
					}
				});
			}
			// tweenCamIn();
		} else {
			if (boyfriend == null)
				return;

			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.camera_position[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.camera_position[1] + boyfriendCameraOffset[1];

			if (SONG.song.toLowerCase() == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1) {
				cameraTwn = FlxTween.tween(this, {defaultCamZoom: 1.2}, (Conductor.stepCrochet * 4 / 1000), {
					ease: FlxEase.linear,
					onComplete: function(twn:FlxTween) {
						cameraTwn = null;
					}
				});
			}
		}
	}

	public dynamic function updateIconsScale(elapsed:Float) {
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 20 * 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 20 * 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var mult:Float = FlxMath.lerp(1, Note.waveThing, 0.5);
		Note.waveThing = mult;
	}

	public dynamic function updateIconsPosition() {
		var iconOffset:Int = 26;
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
	}

	override public function update(elapsed:Float) {
		FlxG.camera.followLerp = 0.04 * 1 * 1;
		FlxG.camera.follow(camFollow, LOCKON, 0);

		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / SONG.speed);
		if (startedSong && !paused)
			Conductor.songPosition = FlxG.sound.music.time;
		if (startingSong && !startedSong && !paused) {
			if (startedCountdown) {
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}

		if (unspawnNotes[0] != null) {
			var time:Float = spawnZone;
			if (songSpeed < 1)
				time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1)
				time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time) {
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		#if hxluajit call("onUpdate", [elapsed]); #end
		notes.forEachAlive(function(daNote:Note) {
			if (daNote.strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * daNote.earlyHitMult)) {
				if ((daNote.isSustainNote && daNote.prevNote.wasGoodHit) || daNote.strumTime <= Conductor.songPosition)
					if (daNote.mustPress && cpuControlled && !daNote.ignoreNote)
						goodNoteHit(daNote);
			}
			if (daNote.targetReceptor == null)
				daNote.targetReceptor = !daNote.mustPress ? opponentStrums.getReceptorOfID(daNote.noteData) : playerStrums.getReceptorOfID(daNote.noteData);

			daNote.followStrumNote(daNote.targetReceptor, 0, songSpeed);
			if (daNote.isSustainNote)
				daNote.clipToStrumNote(daNote.targetReceptor);

			if (daNote.wasGoodHit && !daNote.mustPress)
				opponentNoteHit(daNote);

			if (Conductor.songPosition - daNote.strumTime > noteKillOffset) {
				if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
					noteMiss(daNote.noteData);

				daNote.active = daNote.visible = false;
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
				daNote = null;
			}
		});
		songPos = Conductor.songPosition;
		Conductor.lastSongPos = songPos;
		super.update(elapsed);
		updateScore();
		if (health > 2)
			health = 2;
		if (health < 0.4) {
			iconP2.animation.curAnim.curFrame = 0;
			iconP1.animation.curAnim.curFrame = 1;
		} else if (health > 1.6) {
			iconP1.animation.curAnim.curFrame = 0;
			iconP2.animation.curAnim.curFrame = 1;
		} else {
			iconP1.animation.curAnim.curFrame = 0;
			iconP2.animation.curAnim.curFrame = 0;
		}

		var mult:Float = FlxMath.lerp(camFollow.x, yes.x, Math.exp(-elapsed * 3 * camSPEED));

		var mult2:Float = FlxMath.lerp(camFollow.y, yes.y, Math.exp(-elapsed * 3 * camSPEED));
		yes.set(mult, mult2);
		FlxG.camera.focusOn(yes);
		updateIconsScale(elapsed);
		updateIconsPosition();

		curHealth = FlxMath.lerp(curHealth, health, .2 / (60 / 60));
		if (Math.abs(voices.time - Conductor.songPosition) > 20)
			voices.time = Conductor.songPosition;
		if (FlxG.camera.zoom != defaultCamZoom) {
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
		}
		if (camHUD.zoom != 1) {
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
			camUnderlay.zoom = camHUD.zoom;
		}
		songSpeed = SONG.speed;

		if (!cpuControlled)
			keyShit();
		else
			playerDance();

		stagesFunc((s) -> s.updatePost(elapsed));

		#if hxluajit call("onUpdatePost", [elapsed]); #end
		FlxG.camera.focusOn(yes);
		if (controls.CHAR_EDITOR)
			FlxG.switchState(new CharacterEditorState(dad.curCharacter));
		if (controls.ACCEPT && !inCutscene) {
			paused = true;
			openSubState(new PauseSubState(camHUD));
		}
		if (cpuControlled) {
			accuracy = 0;
			songScore = 0;
			songMisses = 0;
			totalHitNotes = 0;
			totalNotes = 0;
			text.text = "BOTPLAY";
		}
	}

	override function openSubState(SubState:FlxSubState) {
		if (paused) {
			if (FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				voices.pause();
			}
		}

		super.openSubState(SubState);
	}

	function resyncVocals():Void {
		FlxG.sound.music.volume = 1;
		voices.volume = 1;
		voices.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		voices.time = Conductor.songPosition;
		voices.play();
	}

	public function unpause() {
		voices.resume();
		FlxG.sound.music.resume();
		paused = false;
		// resyncVocals();
	}

	function get_spawnZone():Float {
		return 1600 / songSpeed;
	}

	private function keyShit():Void {
		// control arrays, order L D R U
		var holdArray:Array<Bool> = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
		var pressArray:Array<Bool> = [
			controls.NOTE_LEFT_P,
			controls.NOTE_DOWN_P,
			controls.NOTE_UP_P,
			controls.NOTE_RIGHT_P
		];
		var releaseArray:Array<Bool> = [
			controls.NOTE_LEFT_R,
			controls.NOTE_DOWN_R,
			controls.NOTE_UP_R,
			controls.NOTE_RIGHT_R
		];
		if (!holdArray.contains(true))
			playerDance();
		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic) {
			notes.forEachAlive(function(daNote:Note) {
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && daNote.parent.wasGoodHit && holdArray[daNote.noteData])
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic) {
			var possibleNotes:Array<Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<Note> = []; // notes to kill later

			notes.forEachAlive(function(daNote:Note) {
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					if (directionList.contains(daNote.noteData)) {
						for (coolNote in possibleNotes) {
							if (coolNote.noteData == daNote.noteData
								&& Math.abs(daNote.strumTime - coolNote.strumTime) < 10) { // if it's the same note twice at < 10ms distance, just delete it
								// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
								dumbNotes.push(daNote);
								break;
							} else if (coolNote.noteData == daNote.noteData
								&& daNote.strumTime < coolNote.strumTime) { // if daNote is earlier than existing note (coolNote), replace
								possibleNotes.remove(coolNote);
								possibleNotes.push(daNote);
								break;
							}
						}
					} else {
						possibleNotes.push(daNote);
						directionList.push(daNote.noteData);
					}
				}
			});

			for (note in dumbNotes) {
				FlxG.log.add("killing dumb ass note at " + note.strumTime);
				note.kill();
				notes.remove(note, true);
				note.destroy();
				note = null;
			}

			possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

			var perfectMode:Bool = false;
			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0) {
				for (shit in 0...pressArray.length) { // if a direction is hit that shouldn't be
					if (pressArray[shit] && !directionList.contains(shit))
						noteMiss(shit);
				}
				for (coolNote in possibleNotes) {
					if (pressArray[coolNote.noteData] && !coolNote.isSustainNote)
						goodNoteHit(coolNote);
				}
			}
		}

		for (i in 0...pressArray.length) {
			var spr:Receptor = playerStrums.getReceptorOfID(i % 4);
			if (spr.animation.curAnim != null && pressArray[spr.noteData] && spr.getAnimationName() != "confirm")
				playerStrums.playStrumAnim("pressed", i);
			if (!holdArray[spr.noteData])
				playerStrums.playStrumAnim("static", i);
		}
	}

	function noteMiss(shit:Int) {
		if (boyfriend.hasAnimation(singAnimations[shit % 4] + 'miss'))
			boyfriend.playAnim(singAnimations[shit % 4] + 'miss', true);
		health -= 0.035;
		if (health < 0)
			health = 0;
		totalNotes += 4;

		songMisses++;
		updateScore();
	}

	function opponentNoteHit(daNote:Note) {
		if (daNote.wasHit)
			return;

		var receptor:Receptor = opponentStrums.getReceptorOfID(daNote.noteData % 4);
		daNote.wasHit = true;

		var char:Character = dad;
		var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, daNote.noteData % 4)))];
		if (daNote.altNote && char.hasAnimation(animToPlay + '-alt'))
			animToPlay += '-alt';
		char.playAnim(animToPlay, true);
		char.holdTimer = 0;
		receptor.playAnim('confirm', true);

		receptor.resetAnim = Conductor.stepCrochet * 1.5 / 1000;

		if (daNote.isSustainNote)
			return;
		daNote.kill();
		notes.remove(daNote, true);
		daNote.destroy();
		//	daNote = null;
	}

	function goodNoteHit(daNote:Note) {
		if (daNote != null && daNote.wasGoodHit || daNote == null)
			return;

		switch (daNote.noteType.toLowerCase()) {
			case 'hurt':
				noteMiss(daNote.noteData);
				daNote.wasGoodHit = true;
				daNote.kill();
				return;
		}

		daNote.wasGoodHit = true;

		var receptor:Receptor = playerStrums.getReceptorOfID(daNote.noteData);
		receptor.playAnim('confirm', true);
		if (cpuControlled)
			receptor.resetAnim = 200 / 1000;

		var char:Character = boyfriend;
		var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, daNote.noteData % 4)))];
		if (daNote.altNote && char.hasAnimation(animToPlay + '-alt'))
			animToPlay += '-alt';
		char.playAnim(animToPlay, true);
		char.holdTimer = 0;
		health += 0.025;

		if (!daNote.isSustainNote) {
			popUpScore(daNote.strumTime, daNote);
			// totalNotes++;
		}

		updateScore();
		if (daNote.isSustainNote)
			return;
		daNote.kill();
		notes.remove(daNote, true);
		daNote.destroy();
		daNote = null;
	}

	public function getFilesFromDir(path:String = "assets/scripts", extension:String = "lua") {
		path = path.replace('\\', "/");
		var files:Array<String> = FileUtil.readDirectory(path, path.split("/").length);
		for (i in 0...files.length) {
			var filePath:String = Path.addTrailingSlash(path) + files[i];
			files[i] = filePath;
			if (!haxe.io.Path.extension(filePath).contains(extension))
				files.remove(files[i]);
		}
		return files;
	}

	#if hxluajit
	public function set(v1:String, v:Dynamic) {
		for (script in scripts)
			script.set(v1, v);
	}

	public function call(func:String, ?args:Array<Any>) {
		args ??= [];
		for (script in scripts)
			script.call(func, args);
	}
	#end

	override function beatHit() {
		notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		characterBopper(curBeat);

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (SONG.notes[Math.floor(curStep / 16)] != null) {
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM) {
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		super.beatHit();

		#if hxluajit
		set("curBeat", curBeat);
		call("onBeatHit");
		#end
	}

	override function sectionHit() {
		FlxG.camera.zoom += 0.015;
		camHUD.zoom += 0.025;

		if (SONG.notes[Std.int(curStep / 16)] != null) {
			if (generatedMusic)
				moveCameraSection();
		}

		super.sectionHit();
	}

	override function stepHit() {
		super.stepHit();
		DiscordClient.changePresence("\nTime Elapsed:" + '${Conductor.songPosition / 1000}', "Song: " + SONG.song + " | Score: " + songScore);

		#if hxluajit
		call("onStepHit");
		set("curStep", curStep);
		#end
	}

	private function popUpScore(strumtime:Float, daNote:Note):Void {
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		voices.volume = 1;
		var score:Int = 350;
		var daRating:String = "sick";
		var isSick:Bool = true;

		if (noteDiff > Conductor.safeZoneOffset * 0.9) {
			daRating = 'shit';
			score = 50;
			totalHitNotes++;
			isSick = false; // shitty copypaste on this literally just because im lazy and tired lol!
		} else if (noteDiff > Conductor.safeZoneOffset * 0.75) {
			daRating = 'bad';
			score = 100;
			totalHitNotes += 2;
			isSick = false;
		} else if (noteDiff > Conductor.safeZoneOffset * 0.2) {
			daRating = 'good';
			totalHitNotes += 3;
			score = 200;

			isSick = false;
		}

		totalNotes += 4;
		if (isSick)
			totalHitNotes += 4;
		if (isSick && !daNote.isSustainNote && FlxG.save.data.splashes == true || cpuControlled && FlxG.save.data.splashes == true )
			spawnSplash(daNote.targetReceptor,daNote);
		
		if (cpuControlled) {
			accuracy = 0;
			score = 0;
			songScore = songMisses = totalHitNotes = totalNotes = 0;
			text.text = "BOTPLAY";
			return;
		}
		songScore += score;

		updateScore();
	}

	function updateScore() {
		text.screenCenter(X);
		if (cpuControlled)
			return;
		accuracy = totalHitNotes / totalNotes;
		text.text = 'Score $songScore // Misses: $songMisses // Accuracy: ${FlxMath.roundDecimal(accuracy * 100, 2)}%';
		text.screenCenter(X);
	}

	public function getSPRofTag(tag:String):FlxSprite {
		if (luaSprites.exists(tag))
			return luaSprites.get(tag);
		else
			return null;
	}

	function get_downScroll():Bool {
		return FlxG.save.data.downScroll == true;
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite {
		#if hxluajit
		if (luaSprites.exists(tag))
			return luaSprites.get(tag);
		if (text && luaTexts.exists(tag))
			return luaTexts.get(tag);
		#end
		return null;
	}

	var pixelStage(get, null):Bool;

	function spawnSplash(receptor:Receptor, daNote:Note) {
		var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		noteSplash.setupNoteSplash(receptor.x, receptor.y, daNote.noteData, pixelStage);
		grpNoteSplashes.add(noteSplash);
	}

	function get_pixelStage():Bool {
		return stageJson.isPixel;
	}
}
