package ume.game;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import ume.assets.UMEAssets;
import ume.backend.SongConductor;
import ume.chart.format.v1.Legacy.Song;
import ume.chart.format.v1.Legacy.SwagSection;
import ume.chart.format.v1.Legacy.SwagSong;
import ume.objects.Bar;
import ume.objects.GameNote;
import ume.objects.HealthIcon;
import ume.objects.Receptor;

class PlayState extends MusicBeatState {
	public static var noteVariant:String = "normal";

	public var playerStrums:FlxTypedGroup<Receptor>;
	public var cpuStrums:FlxTypedGroup<Receptor>;

	public static var song:SwagSong;

	public var renderedNotes:FlxTypedGroup<GameNote>;
	public var notesToRender:Array<GameNote> = [];

	public static var instance:PlayState;

	public var inst:FlxSound;
	public var voices:FlxSound;

	public var playbackRate:Float = 1;
	public var noteKillOffset:Float = 350;

	public var cpuControlled:Bool = false;
	public var downScroll:Bool = true;
	public var middleScroll:Bool = false;

	public var uiGroup:FlxTypedGroup<FlxBasic>;
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	public var healthBar:Bar;
	public var health:Float = 1;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var camHUD:FlxCamera;
	public var scoreTxt:FlxText;
	public var scoreTxtTw:FlxTween;
	public var score:Float = 0;
	public var misses:Float = 0;

	override public function create() {
		instance = this;
		SongConductor.time = -10;

		if (song == null)
			dummySong();
		if (song.song.toLowerCase() == 'senpai' || song.song.toLowerCase() == 'roses' || song.song.toLowerCase() == 'thorns')
			noteVariant = 'pixel';
		else
			noteVariant = "normal";
		SongConductor.changeBPM(song.bpm);
		SongConductor.mapBPMChanges(song);

		voices = new FlxSound();
		inst = new FlxSound();

		////FlxG.sound.cache('assets/songs/${song.song.toLowerCase()}/Inst.ogg');
		// FlxG.sound.cache('assets/songs/${song.song.toLowerCase()}/Voices.ogg');
		loadSoundFiles(song);
		generateNTR();

		hudInit();

		super.create();
		playSong();
		uiGroup.cameras = [camHUD];
		add(uiGroup);
	}

	function hudInit() {
		uiGroup = new FlxTypedGroup();
		renderedNotes = new FlxTypedGroup();
		playerStrums = new FlxTypedGroup();
		cpuStrums = new FlxTypedGroup();
		noteGroup = new FlxTypedGroup();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		var strumHeight:Float = !downScroll ? 50 : FlxG.height - 150;
		for (i in 0...4) {
			var receptor:Receptor = new Receptor(i);
			receptor.x += ((FlxG.width / 2 + receptor.width / 2) + receptor.width * i);
			receptor.downScroll = downScroll;
			receptor.y = strumHeight;
			if (middleScroll)
				receptor.x -= 300;
			playerStrums.add(receptor);
			noteGroup.add(receptor.holdCover);
			noteGroup.add(receptor.holdCoverEnd);
		}
		uiGroup.add(playerStrums);
		for (i in 0...4) {
			var receptor:Receptor = new Receptor(i);
			receptor.downScroll = downScroll;
			receptor.x += receptor.width * i + 10;
			var mult = i < 2 && middleScroll ? 0.25 : 7;
			if (!middleScroll)
				mult = 0.25;
			else
				receptor.alpha = 0.5;
			receptor.x += receptor.width * mult;
			receptor.y = strumHeight;
			cpuStrums.add(receptor);
			noteGroup.add(receptor.holdCover);
			noteGroup.add(receptor.holdCoverEnd);
		}
		uiGroup.add(cpuStrums);
		uiGroup.add(renderedNotes);

		healthBar = new Bar(0, downScroll ? FlxG.height * 0.2 : FlxG.height * 0.9, 'healthBar', function() {
			return health;
		});
		healthBar.setColors(FlxColor.RED, FlxColor.LIME);
		healthBar.setBounds(0, 2);
		healthBar.screenCenter(X);
		uiGroup.add(healthBar);

		iconP1 = new HealthIcon(song.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.screenCenter(X).x += iconP1.width / 3;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(song.player2);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.screenCenter(X).x -= iconP2.width / 3;
		uiGroup.add(iconP2);

		scoreTxt = new FlxText(0, 0).setFormat('assets/font/bookantiqua_bold.ttf', 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK, true);
		scoreTxt.antialiasing = true;
		scoreTxt.text = 'Score: ? // Combo Breaks: ? // Rating: ?';
		scoreTxt.screenCenter(X);
		scoreTxt.y = healthBar.y + 30;

		uiGroup.add(scoreTxt);
	}

	inline function loadSoundFiles(song:SwagSong) {
		voices.loadEmbedded('assets/songs/${song.song.toLowerCase()}/Voices.ogg', false);
		inst.loadEmbedded(UMEAssets.inst(song.song.toLowerCase()), false);

		FlxG.sound.list.add(voices);
		FlxG.sound.list.add(inst);
	}

	inline function playSong() {
		voices.play();
		inst.play();
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function sortByShit(Obj1:GameNote, Obj2:GameNote):Int {
		return sortNotes(FlxSort.ASCENDING, Obj1, Obj2);
	}

	public function generateNTR() {
		var sections:Array<SwagSection> = song.notes;

		for (i in 0...sections.length) {
			var sectionData = sections[i].sectionNotes;
			for (ii in 0...sectionData.length) {
				try {
				var gottaHitNote:Bool = sections[i].mustHitSection;
					var sussyLengy:Float = sectionData[ii][2];

				var oldNote:GameNote;
				if (notesToRender.length > 0)
					oldNote = notesToRender[Std.int(notesToRender.length - 1)];
				else
					oldNote = null;

					if (sectionData[ii][1] > 3) {
					gottaHitNote = !sections[i].mustHitSection;
				}
					var note:GameNote = new GameNote(sectionData[ii][0], Std.int(sectionData[ii][1]), false, oldNote);
				note.mustPress = gottaHitNote;
				notesToRender.push(note);

				var sussyLength:Float = sussyLengy / SongConductor.stepCrochet;

					for (susNote in 0...Math.floor(sussyLength)) {
					oldNote = notesToRender[Std.int(notesToRender.length - 1)];

					var sustain:GameNote = new GameNote(note.hitTime
						+ (SongConductor.stepCrochet * susNote)
						+ (SongConductor.stepCrochet / FlxMath.roundDecimal(song.speed, 2)),
						note.dataNote, true, oldNote);
					sustain.mustPress = gottaHitNote;
					notesToRender.push(sustain);
				}
				// sorting
			}
				catch (e:Dynamic) {
					trace('ERROR: $e.');
				}
			}
			notesToRender.sort(sortByShit);
		}
	}

	inline function dummySong() {
		song = Song.loadFromJson('pico-hard', 'pico');
	}
	public dynamic function updateIconsScale(elapsed:Float) {
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, 0.9);
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, 0.9);
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}

	public dynamic function updateIconsPosition() {
		var iconOffset:Int = 26;
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		iconP1.updateHitbox();
		iconP2.updateHitbox();
	}

	override public function update(elapsed:Float) {
		if (scoreTxt.text != 'Score: $score | Misses: $misses')
			scoreTxt.text = 'Score: $score | Misses: $misses ';
		keyShit();

		#if FLX_PITCH
		inst.pitch = playbackRate;
		voices.pitch = playbackRate;
		#end
		noteKillOffset = Math.max(SongConductor.stepCrochet, 350 / song.speed * playbackRate);
		FlxG.timeScale = playbackRate;

		if (FlxG.keys.justPressed.SEVEN)
			FlxG.switchState(new ume.game.charting.ChartingState());

		position();

		for (index => note in notesToRender) {
			if (note.hitTime - SongConductor.time < 1500 / song.speed) {
				var dunceNote:GameNote = note;
				renderedNotes.add(dunceNote);

				var index:Int = notesToRender.indexOf(note);
				notesToRender.splice(index, 1);
			}
		}

		super.update(elapsed);
		renderedNotes.forEachAlive(function(note:GameNote) {
			var s = note.mustPress ? playerStrums : cpuStrums;
			var receptor:Receptor = s.members[note.dataNote % s.length];

			note.followStrumNote(receptor, 0, song.speed);

			if (receptor.reduceSustains && note.isSustainNote)
				note.clipToStrumNote(receptor);

			if (!note.mustPress && note.wasGoodHit && !note.hitByOpponent) {
				note.hitByOpponent = true;
				receptor.playAnim('confirm', true);
				receptor.resetAnim = SongConductor.stepCrochet * 1.2 / 1000 / playbackRate;
				if (note.isSustainNote && note.animation.curAnim.name != 'holdend')
					receptor.holdTimer = 0.1;
				if (note.animation.curAnim.name == 'holdend')
					receptor.holdTimer = .01;
				if (!note.isSustainNote)
					invalNote(note);
			}
			// Kill extremely late notes and cause misses
			if (SongConductor.time - note.hitTime > noteKillOffset) {
				if (note.mustPress && !cpuControlled && !note.ignoreNote && (note.tooLate || !note.wasGoodHit))
					noteMiss(note);

				note.active = note.visible = false;
				invalNote(note);
			}
		});
		updateIconsScale(elapsed);
		updateIconsPosition();
		iconP1.origin.y = -0;
		iconP2.origin.y = -0;
	}

	function noteMiss(daNote:GameNote):Void { // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		renderedNotes.forEachAlive(function(note:GameNote) {
			if (daNote != note
				&& daNote.mustPress
				&& daNote.dataNote == note.dataNote
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.hitTime - note.hitTime) < 1)
				invalNote(note);
		});

		noteMissCommon(daNote.dataNote, daNote);
	}

	function noteMissCommon(direction:Int, note:GameNote = null) {
		misses++;
		health -= 0.050;
	}

	function invalNote(note:GameNote) {
		note.kill();
		renderedNotes.remove(note, true);
		note.destroy();
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

		var perfectMode = false;
		// HOLDS, check for sustain notes
		if (holdArray.contains(true) /*!boyfriend.stunned && */) {
			renderedNotes.forEachAlive(function(daNote:GameNote) {
				if (daNote.isSustainNote && daNote.canBeHit && holdArray[daNote.dataNote % 4] && daNote.mustPress)
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true)) {
			// boyfriend.holdTimer = 0;

			var possibleNotes:Array<GameNote> = []; // notes that can be hit
			var directionList:Array<Float> = []; // directions that can be hit
			var dumbNotes:Array<GameNote> = []; // notes to kill later

			renderedNotes.forEachAlive(function(daNote:GameNote) {
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					if (directionList.contains(daNote.dataNote)) {
						for (coolNote in possibleNotes) {
							if (coolNote.dataNote == daNote.dataNote
								&& Math.abs(daNote.hitTime - coolNote.hitTime) < 10) { // if it's the same note twice at < 10ms distance, just delete it
								// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
								dumbNotes.push(daNote);
								break;
							} else if (coolNote.dataNote == daNote.dataNote
								&& daNote.hitTime < coolNote.hitTime) { // if daNote is earlier than existing note (coolNote), replace
								possibleNotes.remove(coolNote);
								possibleNotes.push(daNote);
								break;
							}
						}
					} else {
						possibleNotes.push(daNote);
						directionList.push(daNote.hitTime);
					}
				}
			});

			for (note in dumbNotes) {
				FlxG.log.add("killing dumb ass note at " + note.hitTime);
				note.kill();
				renderedNotes.remove(note, true);
				note.destroy();
			}

			possibleNotes.sort((a, b) -> Std.int(a.hitTime - b.hitTime));

			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0) {
				for (coolNote in possibleNotes) {
					if (pressArray[coolNote.dataNote % 4])
						goodNoteHit(coolNote);
				}
			}
		}

		playerStrums.forEach(function(spr:Receptor) {
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.playAnim('press');
			if (!holdArray[spr.ID])
				spr.playAnim('static');
		});
	}

	override function beatHit() {
		renderedNotes.sort(sortNotes, FlxSort.DESCENDING);
		super.beatHit();
		iconP1.scale.set(1.1, 1.1);
		iconP2.scale.set(1.1, 1.1);
	}

	function sortNotes(order:Int = FlxSort.ASCENDING, Obj1:GameNote, Obj2:GameNote) {
		return FlxSort.byValues(order, Obj1.hitTime, Obj2.hitTime);
	}

	inline function position() {
		if (Math.abs(voices.time - inst.time) > 20) {
			voices.time = inst.time;
		}
		SongConductor.time = inst.time;
	}

	function goodNoteHit(n:GameNote) {
		if (n.wasGoodHit)
			return;

		scoreTxt.alpha = 1;
		scoreTxt.scale.set(1.2, 1.2);
		FlxTween.cancelTweensOf(scoreTxt);
		FlxTween.tween(scoreTxt, {"scale.x": 1, "scale.y": 1, alpha: 0.8}, 0.2);
		scoreTxt.screenCenter(X);
		scoreTxt.x = Math.floor(scoreTxt.x);
		n.wasGoodHit = true;
		var timing:Float = Math.abs(n.hitTime - SongConductor.time);
		var quantized:Int = Math.floor(timing / 5) * 5;
		score += !n.isSustainNote ? 175 : 22 * (1 - Math.floor(quantized / SongConductor.safeZoneOffset));
		health += 0.025;

		playerStrums.forEach(function(spr:Receptor) {
			if (Math.abs(n.dataNote % 4) == spr.dataNote % 4) {
				if (n.isSustainNote) {
					spr.holdTimer = 0.1;
					if (n.animation.curAnim.name == 'holdend')
						spr.holdTimer = .01;
				}

				spr.playAnim('confirm', true);
			}
		});

		if (!n.isSustainNote)
			invalNote(n);
	}
}
