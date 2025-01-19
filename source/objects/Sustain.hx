package objects;

import flixel.graphics.tile.FlxDrawQuadsItem;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.addons.display.FlxTiledSprite;

class Sustain extends FlxSprite {
	public var parent:FlxSprite;  // The note this trail belongs to.
    
    public var bodyAnimation:String;
    public var endAnimation:String;

    public var tileHeight:Float; // Height of the sustain tile.
    public var numTiles:Float;   // Number of sustain tiles.
    
    public var sustainRect:FlxRect;

    // Constructor
    public function new(parent:FlxSprite, graphic:Dynamic, tileHeight:Float = 16) {
        super();

        this.parent = parent;
        this.tileHeight = tileHeight;

        // Load graphic for sustains
        loadGraphic(graphic, true,20,20);
		animation.add("es",[0]);
		animation.play("es");

        // Animation setup
        bodyAnimation = "sustainPiece";
        endAnimation = "sustainEnd";
        
        scale.x = 0.7;
        alpha = 0.6;

        sustainRect = new FlxRect(0, 0, 0, 0);
    }

   
    
}

