package ume.game;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import ume.backend.SongConductor;
import ume.chart.format.v1.Legacy.Song;
import ume.chart.format.v1.Legacy.SwagSong;
import ume.objects.GameNote;
import ume.objects.Receptor;

class PlayState extends MusicBeatState
{
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

	public var downScroll:Bool = false;

	override public function create()
	{
		instance = this;

		if (song == null)
			dummySong();
		SongConductor.changeBPM(song.bpm);
		SongConductor.mapBPMChanges(song);

		renderedNotes = new FlxTypedGroup();
		playerStrums = new FlxTypedGroup();
		cpuStrums = new FlxTypedGroup();

		voices = new FlxSound();
		inst = new FlxSound();

		FlxG.sound.cache('assets/songs/${song.song.toLowerCase()}/Inst.ogg');
		FlxG.sound.cache('assets/songs/${song.song.toLowerCase()}/Voices.ogg');

		generateNTR(song);
		loadSoundFiles(song);

		genPlrStr();
		add(renderedNotes);
		super.create();
		FlxG.camera.bgColor = FlxColor.GRAY;
		playSong();
	}

	inline function loadSoundFiles(song:SwagSong)
	{
		voices.loadEmbedded('assets/songs/${song.song.toLowerCase()}/Voices.ogg', false);
		inst.loadEmbedded('assets/songs/${song.song.toLowerCase()}/Inst.ogg', false);

		FlxG.sound.list.add(voices);
		FlxG.sound.list.add(inst);
	}

	inline function playSong()
	{
		voices.play();
		inst.play();
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function sortByShit(Obj1:GameNote, Obj2:GameNote):Int
	{
		return sortNotes(FlxSort.ASCENDING, Obj1, Obj2);
	}

	inline function generateNTR(song:SwagSong)
	{
		var songData = song.notes;
		var sections = songData;

		for (i in 0...sections.length)
		{
			var sectionData = sections[i].sectionNotes;
			for (ii in 0...sectionData.length)
			{
				var metaNote:Array<Float> = sectionData[ii];
				var gottaHitNote:Bool = sections[i].mustHitSection;
				var sussyLengy:Float = metaNote[2];

				var oldNote:GameNote;
				if (notesToRender.length > 0)
					oldNote = notesToRender[Std.int(notesToRender.length - 1)];
				else
					oldNote = null;

				if (metaNote[1] > 3)
				{
					gottaHitNote = !sections[i].mustHitSection;
				}
				var note:GameNote = new GameNote(metaNote[0], Std.int(metaNote[1]), false, oldNote);
				note.mustPress = gottaHitNote;
				notesToRender.push(note);

				var sussyLength:Float = sussyLengy / SongConductor.stepCrochet;

				for (susNote in 0...Math.floor(sussyLength))
				{
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
			notesToRender.sort(sortByShit);
		}
	}

	inline function genPlrStr()
	{
		var strumHeight:Float = !downScroll ? 50 : FlxG.height - 150;
		for (i in 0...4)
		{
			var receptor:Receptor = new Receptor(i);
			receptor.x += ((FlxG.width / 2 + receptor.width / 2) + receptor.width * i);
			receptor.downScroll = downScroll;
			receptor.y = strumHeight;
			playerStrums.add(receptor);
		}
		add(playerStrums);
		for (i in 0...4)
		{
			var receptor:Receptor = new Receptor(i);
			receptor.downScroll = downScroll;
			receptor.x += receptor.width * i + 10;
			receptor.x += receptor.width * 0.25;
			receptor.y = strumHeight;
			cpuStrums.add(receptor);
		}
		add(cpuStrums);
	}

	inline function dummySong()
	{
		song = Song.loadFromJson('milf-hard', 'milf');
	}

	override public function update(elapsed:Float)
	{
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

		for (index => note in notesToRender)
		{
			if (note.hitTime - SongConductor.time < 1500 / song.speed)
			{
				var dunceNote:GameNote = note;
				renderedNotes.add(dunceNote);

				var index:Int = notesToRender.indexOf(note);
				notesToRender.splice(index, 1);
			}
		}

		super.update(elapsed);

		renderedNotes.forEachAlive(function(note:GameNote)
		{
			var s = note.mustPress ? playerStrums : cpuStrums;
			var receptor:Receptor = s.members[note.dataNote % s.length];

			note.followStrumNote(receptor, 0, song.speed);

			if (receptor.reduceSustains && note.isSustainNote)
				note.clipToStrumNote(receptor);

			if (!note.mustPress && note.wasGoodHit && !note.hitByOpponent)
			{
				note.hitByOpponent = true;
				receptor.playAnim('confirm', true);
				receptor.resetAnim = 1000 * 1.25 / 1000 / playbackRate;

				if (!note.isSustainNote)
					invalNote(note);
			}
			// Kill extremely late notes and cause misses
			if (SongConductor.time - note.hitTime > noteKillOffset)
			{
				if (note.mustPress && !cpuControlled && !note.ignoreNote && (note.tooLate || !note.wasGoodHit))
					noteMiss(note);

				note.active = note.visible = false;
				invalNote(note);
			}
		});
	}

	function noteMiss(daNote:GameNote):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		renderedNotes.forEachAlive(function(note:GameNote)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.dataNote == note.dataNote
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.hitTime - note.hitTime) < 1)
				invalNote(note);
		});

		noteMissCommon(daNote.dataNote, daNote);
	}

	function noteMissCommon(direction:Int, note:GameNote = null) {}

	function invalNote(note:GameNote)
	{
		note.kill();
		renderedNotes.remove(note, true);
		note.destroy();
	}

	private function keyShit():Void
	{
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
		if (holdArray.contains(true) /*!boyfriend.stunned && */)
		{
			renderedNotes.forEachAlive(function(daNote:GameNote)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.dataNote])
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true))
		{
			// boyfriend.holdTimer = 0;

			var possibleNotes:Array<GameNote> = []; // notes that can be hit
			var directionList:Array<Float> = []; // directions that can be hit
			var dumbNotes:Array<GameNote> = []; // notes to kill later

			renderedNotes.forEachAlive(function(daNote:GameNote)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (directionList.contains(daNote.dataNote))
					{
						for (coolNote in possibleNotes)
						{
							if (coolNote.dataNote == daNote.dataNote && Math.abs(daNote.hitTime - coolNote.hitTime) < 10)
							{ // if it's the same note twice at < 10ms distance, just delete it
								// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
								dumbNotes.push(daNote);
								break;
							}
							else if (coolNote.dataNote == daNote.dataNote && daNote.hitTime < coolNote.hitTime)
							{ // if daNote is earlier than existing note (coolNote), replace
								possibleNotes.remove(coolNote);
								possibleNotes.push(daNote);
								break;
							}
						}
					}
					else
					{
						possibleNotes.push(daNote);
						directionList.push(daNote.hitTime);
					}
				}
			});

			for (note in dumbNotes)
			{
				FlxG.log.add("killing dumb ass note at " + note.hitTime);
				note.kill();
				renderedNotes.remove(note, true);
				note.destroy();
			}

			possibleNotes.sort((a, b) -> Std.int(a.hitTime - b.hitTime));

			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0)
			{
				for (shit in 0...pressArray.length)
				{ // if a direction is hit that shouldn't be
					if (pressArray[shit] && !directionList.contains(shit))
						noteMissCommon(shit);
				}
				for (coolNote in possibleNotes)
				{
					if (pressArray[coolNote.dataNote])
						goodNoteHit(coolNote);
				}
			}
			else
			{
				for (shit in 0...pressArray.length)
					if (pressArray[shit])
						noteMissCommon(shit);
			}
		}

		playerStrums.forEach(function(spr:Receptor)
		{
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.playAnim('press');
			if (!holdArray[spr.ID])
				spr.playAnim('static');
		});
	}

	override function beatHit()
	{
		renderedNotes.sort(sortNotes, FlxSort.DESCENDING);
		super.beatHit();
	}

	function sortNotes(order:Int = FlxSort.ASCENDING, Obj1:GameNote, Obj2:GameNote)
	{
		return FlxSort.byValues(order, Obj1.hitTime, Obj2.hitTime);
	}

	inline function position()
	{
		if (Math.abs(voices.time - inst.time) > 20)
		{
			voices.time = inst.time;
		}
		SongConductor.time = inst.time;
	}

	function goodNoteHit(n:GameNote)
	{
		if (!n.wasGoodHit)
		{
			n.wasGoodHit = true;

			playerStrums.forEach(function(spr:Receptor)
			{
				if (Math.abs(n.dataNote) == spr.dataNote)
					spr.playAnim('confirm', true);
			});

			if (!n.isSustainNote)
				invalNote(n);
		}
	}
}
