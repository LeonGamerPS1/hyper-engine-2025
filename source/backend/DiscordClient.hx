package backend;

import lime.app.Application;

@:publicFields
class DiscordClient {
	static var APP_ID:String = "1320028873290809364";

	inline static function init() {}

	static function shutdown() {}

	static function changePresence(state:String = "", details:String = "", largeImageKey:String = "biglogo", smallImageKey:String = "smalllogo") {}
}
