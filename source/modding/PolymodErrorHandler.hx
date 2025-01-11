package modding;

import polymod.Polymod.PolymodError;

class PolymodErrorHandler {
    public static function error(err:PolymodError) {
        trace('[${err.severity}] ${err.message}');
    }
}