proc Java args {
	global javapath
	if ![info exist javapath] {
		set javapath [lindex [auto_execok java] 0]
		if {$javapath eq {}} {
			set candidate [glob -nocomplain "$::env(SystemDrive)/Program Files*/java/*/bin/java.exe"]
			if [llength $candidate] {set javapath [lindex $candidate 0]}
		}
	}

	if {$javapath eq {}} {
		error [mc "Java not found.\nTo solve this problem, install JRE or JDK."] {} {CustomError JavaNotFound}
	}

	if {$args eq {}} {
		return $javapath
	} {
		bgopen $javapath {*}$args
	}
}

# vfs의 바이너리를 복사해서 경로를 리턴. vfs에 없으면 임시폴더 임시파일 경로를 리턴.
# 인자가 없으면 임시폴더를 리턴
proc getVFile args {
	global virtualTmpDir

	if ![info exist virtualTmpDir] {
		close [file tempfile virtualTmpDir]
		file delete -force $virtualTmpDir
		file mkdir $virtualTmpDir
	}
	if ![llength $args] {return $virtualTmpDir}

	set fileName [lindex $args 0]
	set realFile [file join $virtualTmpDir $fileName]
	set virtualFile [file join $::vfsRoot binaries $fileName]

	if { ![file exist $realFile] && [file exist $virtualFile] } {
		file copy -force $virtualFile $realFile 
	}
	return $realFile}

proc cleanupVFile {} {
	if [info exist ::virtualTmpDir] {
		file delete -force $::virtualTmpDir
	}
}

# return latest apk including original.
proc getResultApk _apkPath {
	getNativePathArray $_apkPath cApp
	foreach result {signed unsigned path} {
		if [file exists $cApp($result)] {
			return $cApp($result)
		}
	}
	return
}

proc getNativePathArray {apkPath newVar} {
	upvar $newVar cApp

	set cApp(path) $apkPath
	set cApp(name)		[file tail $apkPath]
	set cApp(proj)		[file dirname $::vfsRoot]/projects/$cApp(name)
	set cApp(unsigned)	[file dirname $cApp(path)]/unsigned_$cApp(name)
	set cApp(signed)	[file dirname $cApp(path)]/signed_$cApp(name)
	set cApp(odex)		[file rootname $cApp(path)].odex
	set cApp(dex)		[file nativename $cApp(proj)/classes.dex]
	set cApp(deoDir)	[file rootname $cApp(path)].dex

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

proc ensureFiles args {
	foreach path $args {
		if ![file isfile $path] {
			error [mc {File is required: %s} $path] 
		}
		if ![file readable $path] {
			error [mc {Access denied: %s} $path] 
		}
	}
}

oo::class create Plugin {
	constructor {args body} {
		oo::objdefine [self] method business $args [format {
			. config -cursor wait
			$::View::tCon yview end
			try {%s} finally {
				. config -cursor {}
			}
		} $body]
	}
}

proc plugin args {
	Plugin create {*}$args
}