package backend;

#if hxdiscord_rpc
import hxdiscord_rpc.Types.DiscordEventHandlers;
import hxdiscord_rpc.Types.DiscordUser;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types.DiscordRichPresence;
#end
import lime.app.Application;
import sys.thread.Thread;

@:publicFields
class DiscordClient {
	static var APP_ID:String = "1320028873290809364";

	inline static function init() {
		#if hxdiscord_rpc
		final handlers:DiscordEventHandlers = DiscordEventHandlers.create();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(APP_ID, cpp.RawPointer.addressOf(handlers), 1, "");

		Discord.UpdateHandlers(cpp.RawPointer.addressOf(handlers));
		Thread.create(function():Void {
			while (true) {
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end

				Discord.RunCallbacks();

				Sys.sleep(2); // if it is lower than this or equal to one it will throw  Discord: Error (1000:Request has been terminated Possible causes: the network is offline, Origin is not allowed by Access-Control-Allow-Origin, the page is being unloaded, etc.)
			}
		});

		Application.current.onExit.add(function(i) {
			shutdown();
		});
		#end
	}

	static function shutdown() {
		#if hxdiscord_rpc
		Discord.Shutdown();
		#end
	}

	#if hxdiscord_rpc
	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		final username:String = request[0].username;
		final globalName:String = request[0].username;
		final discriminator:Int = Std.parseInt(request[0].discriminator);

		if (discriminator != 0)
			Sys.println('Discord: Connected to user ${username}#${discriminator} ($globalName)');
		else
			Sys.println('Discord: Connected to user @${username} ($globalName)');
	}
	#end

	static function changePresence(state:String = "", details:String = "", largeImageKey:String = "biglogo", smallImageKey:String = "smalllogo") {
		#if hxdiscord_rpc
		final discordPresence:DiscordRichPresence = DiscordRichPresence.create();
		discordPresence.state = state;
		discordPresence.details = details;
		discordPresence.largeImageKey = largeImageKey;
		discordPresence.smallImageKey = smallImageKey;

		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));
		#end
	}

	#if hxdiscord_rpc
	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		Sys.println('Discord: Disconnected ($errorCode:$message)');
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		Sys.println('Discord: Error ($errorCode:$message)');
	}
	#end
}
