@echo off
echo Installing Required Libraries (It is highly recommended you Install Git-SCM if you havent already!)
@mkdir .haxelib
haxelib install firetongue 2.1.0
haxelib install flixel 5.9.0
haxelib install flixel-addons
haxelib install flixel-ui
haxelib install lime 8.2.2
haxelib install hscript
haxelib install openfl
haxelib run lime setup
haxelib run lime setup flixel
haxelib run flixel setup
haxelib run openfl setup
haxelib install hxluajit 1.0.3
haxelib git polymod https://github.com/larsiusprime/polymod --skip-dependencies
haxelib git jsonpatch https://github.com/EliteMasterEric/jsonpatch --skip-dependencies
haxelib git jsonpath https://github.com/EliteMasterEric/jsonpath --skip-dependencies
haxelib git thx.core https://github.com/fponticelli/thx.core --skip-dependencies
haxelib git thx.semver https://github.com/fponticelli/thx.semver --skip-dependencies
haxelib install hxCodec