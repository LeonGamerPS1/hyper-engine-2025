package modding;

import Type.ValueType;
import flixel.group.FlxGroup.FlxTypedGroup;

class ReflectionFuncs {
	public static function copyTo(fnc:LuaScript) {
		var addCallback = fnc.addCallback;

		addCallback("getProperty", function(variable:String, ?allowMaps:Bool = false) {
			var split:Array<String> = variable.split('.');
			if (split.length > 1)
				return LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split, true, true, allowMaps), split[split.length - 1], allowMaps);
			return LuaUtils.getVarInArray(LuaUtils.getTargetInstance(), variable, allowMaps);
		});

		addCallback("setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = false) {
			var split:Array<String> = variable.split('.');
			if (split.length > 1) {
				LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split, true, true, allowMaps), split[split.length - 1], value, allowMaps);
				return true;
			}
			LuaUtils.setVarInArray(LuaUtils.getTargetInstance(), variable, value, allowMaps);
			return true;
		});

		addCallback("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if (shitMyPants.length > 1)
				realObject = LuaUtils.getPropertyLoop(shitMyPants, true, false);

			if (Std.isOfType(realObject, FlxTypedGroup)) {
				LuaUtils.setGroupStuff(realObject.members[index], variable, value);
				return;
			}

			var leArray:Dynamic = realObject[index];
			if (leArray != null) {
				if (Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return;
				}
				LuaUtils.setGroupStuff(leArray, variable, value);
			}
		});

		
		addCallback("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(shitMyPants.length>1)
				realObject = LuaUtils.getPropertyLoop(shitMyPants, true, false);


			if(Std.isOfType(realObject, FlxTypedGroup))
			{
				var result:Dynamic = LuaUtils.getGroupStuff(realObject.members[index], variable);
				return result;
			}


			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				var result:Dynamic = null;
				if(Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = LuaUtils.getGroupStuff(leArray, variable);
				return result;
			}
			trace("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!");
			return null;
		});
	}
}
