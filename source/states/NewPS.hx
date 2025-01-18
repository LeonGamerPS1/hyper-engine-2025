package states;

import flixel.math.FlxMath;
import flixel.util.FlxSort;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxG;

class NewPS extends MusicBeatState {
	var playerStrums:StrumLine;
	var oppStrums:StrumLine;
	var song:SwagSong = Song.loadFromJson("senpai-hard", "senpai");
	var notes:FlxTypedSpriteGroup<Note> = new FlxTypedSpriteGroup();
	var notesToSpawn:Array<{
		time:Float,
		data:Int,
		mustHit:Bool,
		length:Float,
        isSustainNote:Bool,
	}> = [];

	override function create() {
		super.create();
		oppStrums = new StrumLine();
		Conductor.mapBPMChanges(song);
		Conductor.changeBPM(song.bpm);
		playerStrums = new StrumLine(FlxG.width / 2);

		add(oppStrums);
		add(playerStrums);

		for (i in 0...song.notes.length) {
			var section = song.notes[i];

			for (i in 0...section.sectionNotes.length) {
				var note:Array<Dynamic> = section.sectionNotes[i];
				var time:Float = note[0];
				var data:Int = note[1];
				var length = note[2] is String ? 0.0 : note[2];
				var mustHit = section.mustHitSection;

				if (data > 3)
					mustHit = !section.mustHitSection;

				notesToSpawn.push({
					time: time,
					data: data % 4,
					length: length,
					mustHit: mustHit,
                    isSustainNote:false,
				});

				var parse_lengatha_note:Float = length / Conductor.stepCrochet;

				for (susNote in 0...Math.round(parse_lengatha_note)) {
					notesToSpawn.push({
						time: time + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / song.speed),
						data: data % 4,
						length: length,
						mustHit: mustHit,
                        isSustainNote:true,
					});
				}
			}
		}
		trace(notesToSpawn.length);
		FlxG.sound.playMusic(Paths.inst(Paths.formatSongName(song.song)), 1, false);
		add(notes);
	}

	override function update(elapsed:Float) {
		Conductor.songPosition = FlxG.sound.music.time;
		camera.zoom = FlxMath.lerp(1, camera.zoom, 0.9);

		for (i => v in notesToSpawn) {
			var time = get_spawnZone();
			if (v.time - Conductor.songPosition < time) {
				notesToSpawn.remove(v);
		        
				var strumli = v.mustHit ? playerStrums : oppStrums;
				var recept = strumli.members[v.data];
				var gay = notes.add(new Note(v.time, v.data, v.isSustainNote, notes.members[notes.length - 1], v.mustHit));
				gay.sustainLength = v.length / 1000 * 1;
                gay.targetReceptor = cast recept;
				gay.mustPress = true;
                
			}
		}
		super.update(elapsed);

		for (note in notes) {
			note.followStrumNote(note.targetReceptor, 0, song.speed);
            if(note.isSustainNote)
                note.clipToStrumNote(note.targetReceptor);
			if (note.strumTime <= Conductor.songPosition)
				invalNote(note);
		}
	}

	function invalNote(note:Note) {
		if(note.wasGoodHit)
			return;
		note.wasGoodHit = true;
		
		        if(!note.isSustainNote)
 
		note.targetReceptor.playAnim("confirm",true);
		if(!note.isSustainNote)
		note.sustainLength = Conductor.stepCrochet / 1000 * 1.5;
		note.targetReceptor.resetAnim = note.sustainLength;

		notes.remove(note, true);
		note.kill();
		note.destroy();
		note = null;
	}

	override function sectionHit() {
		super.sectionHit();
		camera.zoom = 1.03;
	}

	function get_spawnZone():Float {
		return 1600 / song.speed;
	}
}
