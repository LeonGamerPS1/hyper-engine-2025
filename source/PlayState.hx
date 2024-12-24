package;

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
import Song.SwagSong;
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
	public var opponentStrums:FlxTypedGroup<Receptor> = new FlxTypedGroup();
	public var playerStrums:FlxTypedGroup<Receptor> = new FlxTypedGroup();

	public var unspawnNotes:Array<Note> = [];
	public var generatedMusic:Bool = true;
	public var cpuControlled(get, null):Bool;

	public var shit:ModuleS;

	public static var instance:PlayState;

	public var scripts:Array<HScript> = [];

	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup(2);

	public var songScore:Float = 0;
	public var yes:FlxPoint = new FlxPoint();

	private var startingSong:Bool = false;
	var startedCountdown:Bool = false;

	public var camHUD:FlxCamera = new FlxCamera();
	public var camUnderlay:FlxCamera = new FlxCamera();
	public var uiGroup:FlxGroup = new FlxGroup();

	var inCutscene:Bool = true;

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

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var stageJson:StageFile;

	override public function create() {
		instance = this;

		if (SONG == null)
			SONG = Song.loadFromJson('dreams of roses-hard', 'dreams of roses');

		parseStage(SONG.stage);

		DiscordClient.changePresence("Song: " + SONG.song);

		camUnderlay.bgColor.alpha = 0;
		FlxG.cameras.add(camUnderlay, false);
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		var globalScripts = FileUtil.readDirectory("assets/scripts", 2).filter(function(ffe:String) {
			return ffe.contains(".hx");
		});
		var songScripts = FileUtil.readDirectory('assets/data/${SONG.song.toLowerCase().replace(" ", "-")}/', 3).filter(function(ffe:String) {
			return ffe.contains(".hx");
		});
		for (i in 0...globalScripts.length) {
			var file = "assets/scripts/" + globalScripts[i];
			var script:HScript = new HScript(file, globalScripts[i]);
			var doPush:Bool = true;
			for (script2 in scripts) {
				if (script2.name == script.name) {
					doPush = false;
					break;
				}
			}
			if (doPush)
				scripts.push(script)
			else
				script.destroy();
		}
		for (i in 0...songScripts.length) {
			var file = 'assets/data/${SONG.song.toLowerCase().replace(" ", "-")}/' + songScripts[i];
			var script:HScript = new HScript(file, songScripts[i]);
			var doPush:Bool = true;
			for (script2 in scripts) {
				if (script2.name == script.name) {
					doPush = false;
					break;
				}
			}
			if (doPush)
				scripts.push(script)
			else
				script.destroy();
		}
		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);
		boyfriend = new Character(SONG.player1, true);
		dad = new Character(SONG.player2, false);
		gf = new Character(SONG.gfVersion, false);
		gfGroup.add(gf);
		dadGroup.add(dad);
		boyfriendGroup.add(boyfriend);
		startCharacterPos(gf);
		startCharacterPos(dad, true);
		startCharacterPos(boyfriend);
		call("onCreate");

		uiGroup.add(text);
		Conductor.changeBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);
		genSkibidi();

		call("onCreatePost");
		uiGroup.add(grpNoteSplashes);

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

		add(uiGroup);
		uiGroup.cameras = [camHUD];
		healthBar.setColors(FlxColor.RED, FlxColor.LIME);

		startingSong = true;

		voices.loadEmbedded('assets/music/${SONG.song.toLowerCase()}/Voices.ogg');
		FlxG.sound.playMusic('assets/music/${SONG.song.toLowerCase()}/Inst.ogg', false);
		FlxG.sound.music.pause();

		// FlxG.sound.music.loadEmbedded('assets/music/${SONG.song.toLowerCase()}/Inst.ogg');

		startCountdown();
	}

	function parseStage(path:String) {
		if (Assets.exists('assets/stages/$path.json'))
			stageJson = cast Json.parse(Assets.getText('assets/stages/$path.json'));
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

		curStage = path;

		switch curStage {
			default:
				new stages.School(this, true);
		}
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

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

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if (gfCheck && char.curCharacter.startsWith('gf')) { // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.position[0];
		char.y += char.position[1];
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
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
			dad.dance();
			gf.dance();
			boyfriend.playAnim('idle');

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);
			introAssets.set('school', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);
			introAssets.set('schoolEvil', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			for (value in introAssets.keys()) {}

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
		FlxG.sound.music.play();
		voices.play();
		FlxG.sound.music.onComplete = function() {
			FlxG.switchState(new SongSel());
		};
		startedSong = true;
		startingSong = false;

		call('onSongStarted');
	}

	function eventNoteEarlyTrigger(obj:Array<Dynamic>):Float {
		switch (obj[2]) {
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int {
		var earlyTime1:Float = eventNoteEarlyTrigger(Obj1);
		var earlyTime2:Float = eventNoteEarlyTrigger(Obj2);
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0] - earlyTime1, Obj2[0] - earlyTime2);
	}

	function genSkibidi() {
		for (i in 0...4) {
			var num:Receptor = new Receptor(i, stageJson.isPixel == true ? true : false);
			num.x += Note.swagWidth * i;
			num.downScroll = downScroll;
			if (downScroll)
				num.y = FlxG.height - 150;
			opponentStrums.add(num);
		}
		for (i in 0...4) {
			var num:Receptor = new Receptor(i, stageJson.isPixel == true ? true : false);

			num.x += Note.swagWidth * i;
			num.x += FlxG.width / 2;
			if (downScroll)
				num.y = FlxG.height - 150;
			num.downScroll = downScroll;
			playerStrums.add(num);
		}

		uiGroup.add(playerStrums);
		uiGroup.add(opponentStrums);
		uiGroup.add(notes);

		healthBar = new Bar(0, FlxG.height * (!downScroll ? 0.89 : 0.11), "healthBar", function() {
			return curHealth;
		}, 0, 2);

		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.json.health_icon, true);
		iconP1.y = healthBar.y - 75;
		//	iconP1.visible = !ClientPrefs.data.hideHud;
		//	iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.json.health_icon, false);
		iconP2.y = healthBar.y - 75;
		//	iconP2.visible = !ClientPrefs.data.hideHud;
		//	iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP2);

		// FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		var sections:Array<SwagSection> = SONG.notes;

		for (section in sections) {
			for (songNotes in section.sectionNotes) {
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;
				var sussyLengy:Float = songNotes[2] is Float ? songNotes[2] : 0;

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

				var swagNote:Note = new Note(daStrumTime, daNoteData, false, oldNote, gottaHitNote, stageJson.isPixel == true ? true : false);
				swagNote.altNote = section.altAnim == true;
				unspawnNotes.push(swagNote);

				var sussyLength:Float = sussyLengy / Conductor.stepCrochet;

				for (susNote in 0...Std.int(sussyLength)) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / SONG.speed), daNoteData, true,
						oldNote, gottaHitNote, stageJson.isPixel == true ? true : false);
					sustainNote.altNote = section.altAnim == true;
					unspawnNotes.push(sustainNote);
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
			sec = totalSection;
		if (sec < 0)
			sec = 0;

		if (SONG.notes[sec] == null)
			return;

		if (gf != null && SONG.notes[sec].gfSection == true) {
			moveCameraToGirlfriend();
			call('onMoveCamera', "gf");
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);

		if (isDad)
			call('onMoveCamera', 'dad');
		else
			call('onMoveCamera', 'boyfriend');
	}

	public function moveCamera(isDad:Bool) {
		if (isDad) {
			if (dad == null)
				return;
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.camera_position[0] + opponentCameraOffset[0];
			camFollow.y += dad.camera_position[1] + opponentCameraOffset[1];
			// tweenCamIn();
		} else {
			if (boyfriend == null)
				return;

			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.camera_position[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.camera_position[1] + boyfriendCameraOffset[1];

			if (SONG.song.toLowerCase() == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1) {
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween) {
						cameraTwn = null;
					}
				});
			}
		}
	}

	public dynamic function updateIconsScale(elapsed:Float) {
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 15 * 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 15 * 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
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
		if (startedSong)
			Conductor.songPosition = FlxG.sound.music.time;
		if (startingSong && !startedSong) {
			if (startedCountdown) {
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		if (unspawnNotes[0] != null) {
			if (unspawnNotes[0].strumTime - Conductor.songPosition < spawnZone) {
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		call("onUpdate", elapsed);
		text.text = '';

		super.update(elapsed);

		var mult:Float = FlxMath.lerp(camFollow.x, yes.x, Math.exp(-elapsed * 3 * 1));

		var mult2:Float = FlxMath.lerp(camFollow.y, yes.y, Math.exp(-elapsed * 3 * 1));
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

		notes.forEachAlive(function(daNote:Note) {
			if (daNote.strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * daNote.earlyHitMult)) {
				if ((daNote.isSustainNote && daNote.prevNote.wasGoodHit) || daNote.strumTime <= Conductor.songPosition)
					if (daNote.mustPress && cpuControlled)
						goodNoteHit(daNote);
			}
			var receptor:Receptor = !daNote.mustPress ? opponentStrums.members[daNote.noteData] : playerStrums.members[daNote.noteData];
			daNote.followStrumNote(receptor, 0, songSpeed);
			if (daNote.isSustainNote && receptor.sustainReduce)
				daNote.clipToStrumNote(receptor);

			if (daNote.wasGoodHit && !daNote.mustPress)
				opponentNoteHit(daNote);

			if (Conductor.songPosition - daNote.strumTime > noteKillOffset) {
				if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
					noteMiss(daNote.noteData);

				daNote.active = daNote.visible = false;
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
		});
		if (!cpuControlled)
			keyShit();
		else
			playerDance();

		call("onUpdatePost", elapsed);
		FlxG.camera.focusOn(yes);
	}

	function get_spawnZone():Float {
		return 2000 / songSpeed;
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
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData])
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
					if (pressArray[coolNote.noteData])
						goodNoteHit(coolNote);
				}
			}
		}

		playerStrums.forEach(function(spr:Receptor) {
			if (spr.animation.curAnim != null && pressArray[spr.noteData] && spr.animation.curAnim.name != 'confirm')
				spr.playAnim('pressed');
			if (!holdArray[spr.noteData])
				spr.playAnim('static');
		});
	}

	function noteMiss(shit:Int) {
		if (boyfriend.hasAnimation(singAnimations[shit % 4] + 'miss'))
			boyfriend.playAnim(singAnimations[shit % 4] + 'miss', true);
		health -= 0.025;
		if (health < 0)
			health = 0;
	}

	function opponentNoteHit(daNote:Note) {
		if (daNote.wasHit)
			return;

		var receptor:Receptor = opponentStrums.members[daNote.noteData % 4];
		daNote.wasHit = true;

		var char:Character = dad;
		var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, daNote.noteData % 4)))];
		if (daNote.altNote && char.hasAnimation(animToPlay + '-alt'))
			animToPlay += '-alt';
		char.playAnim(animToPlay, true);
		char.holdTimer = 0;

		if (FlxG.save.data.strumGlowOpp == true) {
			receptor.playAnim('confirm', true);
			receptor.resetAnim = Conductor.stepCrochet * 1.5 / 1000;
		}
		if (!daNote.isSustainNote) {
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
	}

	function goodNoteHit(daNote:Note) {
		if (daNote.wasGoodHit)
			return;

		daNote.wasGoodHit = true;
		var receptor:Receptor = playerStrums.members[daNote.noteData];
		if (cpuControlled && FlxG.save.data.strumGlowBot == true || !cpuControlled && FlxG.save.data.strumGlowPlr == true)
			receptor.playAnim('confirm', true);
		if (cpuControlled && FlxG.save.data.strumGlowBot == true)
			receptor.resetAnim = Conductor.stepCrochet * 1.5 / 1000;

		var char:Character = boyfriend;
		var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, daNote.noteData % 4)))];
		if (daNote.altNote && char.hasAnimation(animToPlay + '-alt'))
			animToPlay += '-alt';
		char.playAnim(animToPlay, true);
		char.holdTimer = 0;
		health += 0.025;
		if (!daNote.isSustainNote) {
			popUpScore(daNote.strumTime, daNote);

			if (health > 2)
				health = 2;
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
	}

	public function set(v1:String, v:Dynamic) {
		for (script in scripts)
			script.set(v1, v);
	}

	public function call(func:String, ?arg1, ?arg2, ?arg3) {
		for (script in scripts)
			script.call(func, arg1, arg2, arg3);
	}

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

		call("onBeatHit");
		set("curBeat", curBeat);
	}

	override function sectionHit() {
		FlxG.camera.zoom += 0.015;
		camHUD.zoom += 0.025;

		if (SONG.notes[totalSection] != null) {
			if (generatedMusic)
				moveCameraSection();
		}

		super.sectionHit();
	}

	override function stepHit() {
		super.stepHit();
		DiscordClient.changePresence("\nTime Elapsed:" + '${Conductor.songPosition / 1000}', "Song: " + SONG.song + " | Score: " + songScore);

		call("onStepHit");
		set("curStep", curStep);
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
			isSick = false; // shitty copypaste on this literally just because im lazy and tired lol!
		} else if (noteDiff > Conductor.safeZoneOffset * 0.75) {
			daRating = 'bad';
			score = 100;
			isSick = false;
		} else if (noteDiff > Conductor.safeZoneOffset * 0.2) {
			daRating = 'good';
			score = 200;
			isSick = false;
		}

		if (isSick && !daNote.isSustainNote && FlxG.save.data.splashes == true) {
			var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
			noteSplash.setupNoteSplash(playerStrums.members[daNote.noteData % 4].x, playerStrums.members[daNote.noteData % 4].y, daNote.noteData);
			// new NoteSplash(daNote.x, daNote.y, daNote.noteData);
			grpNoteSplashes.add(noteSplash);
		}

		// Only add the score if you're not on cpuControlled mode or the note is a sustain note
		if (cpuControlled || daNote.isSustainNote)
			return;

		songScore += score;
	}

	function get_cpuControlled():Bool {
		return FlxG.save.data.cpuControlled == true;
	}

	function get_downScroll():Bool {
		return FlxG.save.data.downScroll == true;
	}
}
