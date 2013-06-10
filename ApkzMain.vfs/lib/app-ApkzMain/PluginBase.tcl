proc Java args {
	global javapath
	if ![info exist javapath] {
		set javapath [auto_execok java]
		if {$javapath == ""} {
			set candidate [glob -nocomplain "$::env(SystemDrive)/Program Files*/java/*/bin/java.exe"]
			if [llength $candidate] {set javapath [lindex $candidate 0]}
		}
	}

	if {$javapath == {}} {
		error [mc "Java not found.\nTo solve this problem, install JRE or JDK."] {} 100
	}

	# TODO: 이제 저 bgopen은 error를 일으킬 수 있음. 어디서 핸들링할까.
	bgopen ::View::Print $javapath {*}$args
	return 0
}

# vfs의 바이너리를 복사해서 경로를 리턴.
proc getVFile fileName {
	global virtualTmpDir

	if ![info exist virtualTmpDir] {
		close [file tempfile virtualTmpDir]
		file delete -force $virtualTmpDir
		file mkdir $virtualTmpDir
	}

	if ![file exist $virtualTmpDir/$fileName] {
		file copy -force $::vfsRoot/binaries/$fileName $virtualTmpDir/$fileName
	}

	return $virtualTmpDir/$fileName}

proc cleanupVFile {} {
	if [info exist ::virtualTmpDir] {
		if [info exist $::virtualTmpDir] {
			file delete -force $::virtualTmpDir
		}
	}
}

# return latest apk including original.
proc getResult _apkPath {
	GetNativePathArray $_apkPath cApp
	foreach result {signed unsigned path} {
		if [file exists $cApp($result)] {
			return $cApp($result)
		}
	}
	return
}

proc GetNativePathArray {apkPath newVar} {
	upvar $newVar cApp

	set cApp(path) $apkPath
	set cApp(name) [file tail $apkPath]
	set cApp(proj) [file dirname $::vfsRoot]/projects/$cApp(name)
	set cApp(unsigned) [file dirname $cApp(path)]/unsigned_$cApp(name)
	set cApp(signed) [file dirname $cApp(path)]/signed_$cApp(name)

	foreach idx [array names cApp] {
		set cApp($idx) [file nativename $cApp($idx)]
	}
}

proc dlgSelectAppFiles title {
	set types [list \
		[list [mc {All readable file}]	{.apk .jar}] \
		[list [mc {Apk file}]			{.apk}     ] \
		[list [mc {Jar file}]			{.jar}     ] \
		[list [mc {All file}]			{*}        ] \
	]
	
	set apps [tk_getOpenFile -filetypes "$types" \
		-multiple 1 -initialdir $::hist(lastBrowsePath) \
		-title $title]
	
	if {$apps != {}} {
		set ::hist(lastBrowsePath) [file dirname [lindex $apps 0]]
	}
	
	return $apps
}

oo::class create Plugin {
	constructor {args body} {
		oo::objdefine [self] method business $args $body
	}
}

proc plugin args {
	Plugin create {*}$args
}