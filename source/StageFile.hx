package;

typedef StageFile = {
   public var bfOffsets:Null<Array<Float>>;
   public var gfOffsets:Null<Array<Float>>;
   public var dadOffsets:Array<Float>;

   public var cam_dad:Null<Array<Float>>;
   public var cam_bf:Null<Array<Float>>;
   public var cam_gf:Null<Array<Float>>;

   public var isPixel:Null<Bool>;

   public var defaultCamZoom:Null<Float>;
}