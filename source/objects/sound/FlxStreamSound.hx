package objects.sound;

import flixel.FlxG;
import openfl.utils.Assets;
import openfl.utils.AssetType;
import openfl.media.Sound;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.sound.FlxSound;

class FlxStreamSound extends FlxSound {

	override public function loadEmbedded(EmbeddedSound:FlxSoundAsset, Looped:Bool = false, AutoDestroy:Bool = false, ?OnComplete:Void->Void):FlxSound {
		if (EmbeddedSound == null)
			return this;

		cleanup(true);

		if ((EmbeddedSound is Sound)) {
			_sound = EmbeddedSound;
		} else if ((EmbeddedSound is Class)) {
			_sound = Type.createInstance(EmbeddedSound, []);
		} else if ((EmbeddedSound is String)) {
			if (Assets.exists(EmbeddedSound, AssetType.SOUND) || Assets.exists(EmbeddedSound, AssetType.MUSIC))
				_sound = Assets.getMusic(EmbeddedSound);
			
		}

		// NOTE: can't pull ID3 info from embedded sound currently
		return init(Looped, AutoDestroy, OnComplete);
	}
}
