package;

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
	public var notes:FlxTypedGroup<Note> = new FlxTypedGroup();
	public var songSpeed:Float = 1.1;
	public var spawnZone(get, null):Float;

	public static var SONG:SwagSong;

	public var noteKillOffset:Float = 350;

	public var text:FlxBitmapText = new FlxBitmapText(0, 0, "");

	public var defaultCamZoom:Float = 1.0;
	public var voices:FlxSound = new FlxSound();
	public var opponentStrums:FlxTypedGroup<Receptor> = new FlxTypedGroup();
	public var playerStrums:FlxTypedGroup<Receptor> = new FlxTypedGroup();

	public var unspawnNotes:Array<Note> = [];
	public var generatedMusic:Bool = true;
	public var cpuControlled:Bool = true;

	public var shit:ModuleS;

	public static var instance:PlayState;

	public var scripts:Array<HScript> = [];

	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup(4);
	public var songScore:Float = 0;

	public var camHUD:FlxCamera = new FlxCamera();
	public var uiGroup:FlxGroup = new FlxGroup();

	override public function create() {
		instance = this;
		if (SONG == null)
			SONG = Song.loadFromJson('unbeatable', 'unbeatable');

		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		var ass = FileUtil.readDirectory("assets/scripts", 2).filter(function(ffe:String) {
			return ffe.contains(".hx");
		});
		for (i in 0...ass.length) {
			var file = "assets/scripts/" + ass[i];
			var script:HScript = new HScript(file, ass[i]);
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
		call("onCreate");
		text.y += 10;
		text.x += 10;
		uiGroup.add(text);
		genSkibidi();
		Conductor.changeBPM(SONG.bpm);

		call("onCreatePost");
		uiGroup.add(grpNoteSplashes);

		voices.loadEmbedded('assets/music/${SONG.song.toLowerCase()}/Voices.ogg');
		FlxG.sound.list.add(voices);
		FlxG.sound.playMusic('assets/music/${SONG.song.toLowerCase()}/Inst.ogg', false);
		voices.play();

		FlxG.sound.music.onComplete = function() {
			FlxG.switchState(new SongSel());
		};
		super.create();
		add(uiGroup);
		uiGroup.cameras = [camHUD];
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
			var num:Receptor = new Receptor(i);
			num.x += Note.swagWidth * i;
			opponentStrums.add(num);
		}
		for (i in 0...4) {
			var num:Receptor = new Receptor(i);
			num.x += Note.swagWidth * i;
			num.x += FlxG.width / 2;
			playerStrums.add(num);
		}

		uiGroup.add(playerStrums);
		uiGroup.add(opponentStrums);
		uiGroup.add(notes);
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

				var swagNote:Note = new Note(daStrumTime, daNoteData, false, oldNote, gottaHitNote);
				unspawnNotes.push(swagNote);

				var sussyLength:Float = sussyLengy / Conductor.stepCrochet;

				for (susNote in 0...Std.int(sussyLength)) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					var swagNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / SONG.speed), daNoteData, true,
						oldNote, gottaHitNote);
					unspawnNotes.push(swagNote);
				}
			}
		}
		unspawnNotes.sort(sortByShit);
	}

	override public function update(elapsed:Float) {
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / SONG.speed);
		Conductor.songPosition = FlxG.sound.music.time;
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
		if (Math.abs(voices.time - Conductor.songPosition) > 20)
			voices.time = Conductor.songPosition;
		if (FlxG.camera.zoom != defaultCamZoom) {
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
		}
		if (camHUD.zoom != 1) {
			camHUD.zoom = FlxMath.lerp(defaultCamZoom, camHUD.zoom, 0.95);
		}
		songSpeed = SONG.speed;

		notes.forEachAlive(function(daNote:Note) {
			if (daNote.strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * daNote.earlyHitMult)) {
				if ((daNote.isSustainNote && daNote.prevNote.wasGoodHit) || daNote.strumTime <= Conductor.songPosition)
					if (daNote.mustPress)
						goodNoteHit(daNote);
			}
			var receptor:Receptor = !daNote.mustPress ? opponentStrums.members[daNote.noteData] : playerStrums.members[daNote.noteData];
			daNote.followStrumNote(receptor, 0, songSpeed);
			if (daNote.isSustainNote && receptor.sustainReduce)
				daNote.clipToStrumNote(receptor);

			if (daNote.wasGoodHit && !daNote.mustPress && !daNote.wasHit) {
				daNote.wasHit = true;
				receptor.playAnim('confirm', true);
				receptor.resetAnim = Conductor.stepCrochet * 1.5 / 1000;
				if (!daNote.isSustainNote) {
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			}

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

		call("onUpdatePost", elapsed);
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
			} else {
				for (shit in 0...pressArray.length)
					if (pressArray[shit])
						noteMiss(shit);
			}
		}

		playerStrums.forEach(function(spr:Receptor) {
			if (spr.animation.curAnim != null && pressArray[spr.noteData] && spr.animation.curAnim.name != 'confirm')
				spr.playAnim('pressed');
			if (!holdArray[spr.noteData])
				spr.playAnim('static');
		});
	}

	function noteMiss(shit) {}

	function goodNoteHit(daNote:Note) {
		if (daNote.wasGoodHit)
			return;
		daNote.wasGoodHit = true;
		var receptor:Receptor = playerStrums.members[daNote.noteData];
		receptor.playAnim('confirm', true);
		if (cpuControlled)
			receptor.resetAnim = Conductor.stepCrochet * 1.5 / 1000;
		if (!daNote.isSustainNote) {
			popUpScore(daNote.strumTime, daNote);
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
		super.beatHit();
		notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		if (curBeat % 4 == 0) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.025;
		}
		call("onBeatHit");
		set("curBeat", curBeat);
	}

	override function stepHit() {
		super.stepHit();

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

		if (isSick) {
			var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
			noteSplash.setupNoteSplash(daNote.x, daNote.y, daNote.noteData);
			// new NoteSplash(daNote.x, daNote.y, daNote.noteData);
			grpNoteSplashes.add(noteSplash);
		}

		// Only add the score if you're not on cpuControlled mode
		if (!cpuControlled)
			songScore += score;
	}
}
