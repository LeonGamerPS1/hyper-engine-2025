package effects;

import openfl.Assets;
import flixel.addons.display.FlxRuntimeShader;

class Shader extends FlxRuntimeShader {
    public function new(path:String = "") {
        super(Assets.getText(Paths.shaderFrag(path)));
    }
}