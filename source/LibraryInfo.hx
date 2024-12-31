package;

@:build(macros.LibraryInfoMacro.setLibrarys())
class LibraryInfo {
   public static var librarys(get,null):String;
   

    static function get_librarys():String {
        return "[];";
    }
}