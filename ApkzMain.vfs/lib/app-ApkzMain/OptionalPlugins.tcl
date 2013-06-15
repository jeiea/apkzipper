plugin {Recompress ogg} apkPath {
	getNativePathArray $apkPath cApp

	foreach ogg [scan_dir $cApp(proj) *.ogg] {
		set subpath [file nativename [string map [list [file dirname $cApp(proj)]/ ""] [file normalize $ogg]]]
		::View::Print "[mc Processing]$subpath\n"
		Sox  $ogg -C 0 $ogg
	}
}

plugin Sox args {
	set tmpdir [file dirname [getVFile sox.exe]]
	getVFile zlib1.dll
	getVFile pthreadgc2.dll

	bgopen ::View::Print [getVFile sox.exe] {*}$args
}