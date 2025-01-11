package;

import flixel.FlxG;
#if hxCodec

import hxcodec.flixel.FlxVideo;
#end
import flixel.FlxState;
import haxe.Constraints.Function;

class VideoState extends FlxState {
	#if hxCodec
	#end
	public var finishCallback:Function;
	public var videoPath:String = "";

	public function new(videoPath:String, ?finishCallback:Function) {
		super();
		this.finishCallback = finishCallback;
		this.videoPath = videoPath;
	}

	override function create() {
		super.create();
		#if hxCodec
		var video:FlxVideo = new FlxVideo();
		video.onEndReached.add(function() {
			video.dispose();
			finishCallback();
		});
		video.play('$videoPath');
		#else
		finishCallback();
		#end
	}
}
