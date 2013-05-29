
set types "
	{{[mc ALL_READABLE_FILE]} {.apk .jar}}
    {{[mc APK_FILE]} {.apk}}
    {{[mc JAR_FILE]} {.jar}}
    {{[mc ALL_FILE]} {*}}
"
set currentOp ""

proc CommandParser command {
	set cmd [lindex $command 0]
	if [string is digit $cmd] {
		TraverseCApp [lindex $::btns [expr $cmd * 3 + 2]]
	}
}

proc TraverseCApp methodName {
	global cAppPaths currentOp
	if {$methodName == {Select_app}} {Select_app; return}
	if {$currentOp != ""} {
		if ![winfo exist .mlsWait] {
			toplevel .mlsWait
			wm title .mlsWait [mc PLEASE_WAIT]
			pack [ttk::label .mlsWait.msg -text [mc PLEASE_WAIT]\n[mc ALREADY_OP_EXIST]] -expand 1 -fill both
		}
		raise .mlsWait
		after 3000 {destroy .mlsWait}
		return
	}
	
	set currentOp $methodName
	try { # catch {}
		if [info exist cAppPaths] {
			foreach apkPath $cAppPaths {
				set ret [catch {$methodName $apkPath} errinfo]
				if $ret {Print "ERROR $ret: [dict get $errinfo -errorinfo]\n"}
			}
		}
	} finally {set currentOp ""}
}

#proc Select_app {{default ""}} { ;#�̰� ���߿�. ���� ���ݳֱ�� step by step�ϱ� ���� �̷��.
proc Select_app {} {
	global types
	
	# TODO: ���� �̰͵� �⺻ ���� ��ġ ����. ���߿�.
	#if [string equal $default ""] {set initialfile ""} {set initialfile "-initialfile $default"}
	
	# �����Ƽ� �ϴ� �̸� �����ص�.
	global cAppPaths
	set cAppPaths [list [file normalize "$::argv0/../../../../modding/SystemUI.apk"]]
	# [file normalize "$::argv0/../../../../modding/);(!d! %o%&��\}.apk"]]
	#set cAppPaths [tk_getOpenFile -filetypes "$types" -multiple 1 -initialdir [file dirname $::vfsdir] -title [mc OPEN_MULTIPLE_FILES_DIALOG_TITLE]]
	if {$cAppPaths != ""} {
		set ::capps [file tail [lindex $cAppPaths 0]]
	}
}

proc GetNativePathArray {apkPath newVar} {
	upvar $newVar cApp
	
	set cApp(path) $apkPath
	set cApp(name) [file tail $apkPath]
	set cApp(proj) [file dirname $::vfsdir]/projects/$cApp(name)
	set cApp(unsigned) [file dirname $cApp(path)]/unsigned_$cApp(name)
	set cApp(signed) [file dirname $cApp(path)]/signed_$cApp(name)
	
	foreach idx [array names cApp] {
		set cApp($idx) [file nativename $cApp($idx)]
	}
}

# vfs�� ���̳ʸ��� �����ؼ� ��θ� ����. vfsMap(fileName)�� �������� ������.
proc GetVFile fileName {
	global vfsMap
	if ![info exist vfsMap($fileName)] {
		close [file tempfile vfsMap($fileName) $fileName]
		file copy -force $::vfsdir/binaries/$fileName $vfsMap($fileName)
	}
	return $vfsMap($fileName)
}

# HACK: �ӽ������� �̸��� ��ΰ� ����Ǹ� ���ڴµ�... ����� ����� ����?
proc Adb args {
	set tmpdir [file dirname [GetVFile adb.exe]]
	if ![file exists $tmpdir/AdbWinApi.dll] {file copy -force $::vfsdir/binaries/AdbWinApi.dll $tmpdir/AdbWinApi.dll}
	if ![file exists $tmpdir/AdbWinUsbApi.dll] {file copy -force $::vfsdir/binaries/AdbWinUsbApi.dll $tmpdir/AdbWinUsbApi.dll}
	
	return [bgopen Print [GetVFile adb.exe] {*}$args]
}

proc Adb_pull args {
	
	[tk_getOpenFile -filetypes "$types" -multiple 1 -initialdir [file dirname $::vfsdir] -title [mc SELECT_FRAMEWORK_FILE_OR_FOLDER]]
}

proc Sox args {
	set tmpdir [file dirname [GetVFile sox.exe]]
	if ![file exists $tmpdir/zlib1.dll] {file copy -force $::vfsdir/binaries/zlib1.dll $tmpdir/zlib1.dll}
	if ![file exists $tmpdir/pthreadgc2.dll] {file copy -force $::vfsdir/binaries/pthreadgc2.dll $tmpdir/pthreadgc2.dll}
	
	bgopen Print [GetVFile sox.exe] {*}$args
}

proc Java args {
	global javapath
	if ![info exist javapath] {
		set javapath [auto_execok java]
		if {$javapath == ""} {
			set candidate [glob -nocomplain ${env(SystemDrive)}/Program Files*/java/*/bin/java.exe]
			if [llength $candidate] {set javapath [lindex $candidate 0]}
		}
	}
	
	if {$javapath == {}} {
		tk_messageBox -message [mc CANNOT_FIND_JAVA] -icon error -type ok
		return
	}
	
	# HACK: �������� ��δ� �� �ٷ�� ��ƴ�. �Ф� ������ �ǹ��� ǰ�� ����ٴ�...
	return [bgopen Print $javapath {*}$args]
}

foreach jarfile {Apktool Signapk} {
	proc $jarfile args "
		return \[Java -jar \[GetVFile $jarfile.jar] {*}\$args]
	"
}

foreach exefile {Fastboot Optipng 7za} {
	proc $exefile args "
		return \[bgopen Print \[GetVFile $exefile.exe] {*}\$args]
	"
}

proc Extract apkPath {
	GetNativePathArray $apkPath cApp
	
	if [file exist $cApp(proj)] {
		file delete $::forcedelete $cApp(proj)
	}
	7za x -y -o$cApp(proj) $cApp(path)
}

proc Decompile apkPath {
	GetNativePathArray $apkPath cApp
	
	Apktool d -f $cApp(path) $cApp(proj) ;# decopt
	7za -y x -o$cApp(proj) $cApp(path) META-INF -r
}

proc Compile {apkPath args} {
	GetNativePathArray $apkPath cApp
	
	if ![file isdirectory $cApp(proj)] {
		tk_messageBox -message "Please extract/decompile app first." -icon info -type ok
		return
	}
	
	if {[file extension $cApp(path)] == ".jar"} {
		Print "jar compiling..."
		7za -y x -o$cApp(proj) $cApp(path) META-INF -r
	} else {
		Print "apk compiling..."
	}
	
	if [Apktool b -a [GetVFile aapt.exe] $cApp(proj) $cApp(unsigned)] {
		Print "Decompile failed. Task terminated.\n"
		return
	}
	Print "Adjusting compressing level..."
	# INFO: -aoa�� overwrite all destination files�̴�
	7za -y x -aoa -o$cApp(proj)\\temp $cApp(unsigned)
	
	if {$args != {}} {
		foreach metafile {resources.arsc AndroidManifest.xml} {
			7za -y x -aoa -o$cApp(proj)\\temp $cApp(path) $metafile
		}
	}
	
	if [file isdirectory $cApp(proj)/META-INF] {
		file copy -force -- $cApp(proj)/META-INF $cApp(proj)/temp/META-INF
	}
	
	file delete $cApp(unsigned)
	7za -y a -tzip -mx$::zlevel $cApp(unsigned) $cApp(proj)\\temp\\*
	file delete -force $cApp(proj)\\temp
}

proc Zip apkPath {
	GetNativePathArray $apkPath cApp
	
	if ![file isdirectory $cApp(proj)] {
		tk_messageBox -message "Please extract/decompile app first." -icon info -type ok
		return
	}
	
	Print Compressing...
	file delete $cApp(unsigned)
	7za -y a -tzip -mx$::zlevel $cApp(unsigned) $cApp(proj)\\*
}

proc System_compile apkPath {
	Compile $apkPath -sys
}

proc Compression_level {} {
}

proc Decompile_target {} {}

proc Install_framework {} {
	global types
	set frameworks [tk_getOpenFile -filetypes "$types" -multiple 1 -initialdir [file dirname $::vfsdir] -title [mc SELECT_FRAMEWORK_FILE_OR_FOLDER]]
	if {$frameworks != ""} {
		foreach framework $frameworks {Apktool if $framework}
	}
}

proc Sign apkPath {
	GetNativePathArray $apkPath cApp
	
	Signapk -w [GetVFile testkey.x509.pem] [GetVFile testkey.pk8] $cApp(unsigned) $cApp(signed)
	
}

proc Zipalign apkPath {
	GetNativePathArray $apkPath cApp
	
	foreach workingFile {$cApp(signed) $cApp(unsigned) $cApp(path)} {
		exec [GetVFile zipalign.exe] -f 4 "%%~fA" "%%~dpAaligned_%%~nxA" && del /Q "%%~A" && ren "%%~dpAaligned_%%~nxA" "%%~nxA"
	}
}

# TODO: ���� ���ϰ�θ� �������� �����η� ����..? ����
# TODO: �ٸ� ���ϵ� �ڵ����� Ǫ���ϵ���... �̰� �巡�׷� ó���ϸ� ������ �Ф�
proc Adb_push apkpath {
	global types
	set filesToPush [tk_getOpenFile -filetypes "$types" -multiple 1 -initialdir [file dirname $::vfsdir] -title [mc SELECT_FILES_OR_FOLDER_TO_PUSH]]
	Adb push "" ""
	foreach item $filesToPush {}
}

proc Adb_install apkpath {
	Adb install $apkPath
}

proc Explore_project apkPath {
	GetNativePathArray $apkPath cApp
	
	catch {exec explorer $cApp(proj)}
}

proc Optimize_png apkPath {
	GetNativePathArray $apkPath cApp
	
	foreach pngfile [scan_dir $cApp(proj) *.png] {
		Optipng $pngfile
	}
	
}

proc Squeeze_ogg apkPath {
	GetNativePathArray $apkPath cApp
	
	foreach ogg [scan_dir $cApp(proj) *.ogg] {
		set subpath [file nativename [string map [list [file dirname $cApp(proj)]/ ""] [file normalize $ogg]]]
		Print "[mc PROCESSING]$subpath\n"
		Sox  $ogg -C 0 $ogg
		# ī��Ʈ��� �߰�, verbose������ �߰� -V6
	}
}

proc Switch_sign apkPath {
	GetNativePathArray $apkPath cApp
	if ![file exist $cApp(proj) {Extract $apkPath}
	
	if [file exist $cApp(proj)/META-INF] {
		file delete -force $cApp(proj)/META-INF
		set prompt ������.
	} {
		7za -y x -o$cApp(proj) $cApp(path) META-INF -r
	}
}

proc Adb_logcat {} {
	set chan [open "|[GetVFile adb.exe] logcat" r]
	#fconfigure $chan -blocking false
	after 2000 "
		close $chan
		close $logcatfile
	"
	set logcatfile [open "$::vfsdir/../logcat.txt" w]
	fcopy $chan $logcatfile
}

proc Adb_connect {} {
	
}

proc Read_log {} {
	exec cmd /c start $argv0
}

proc Clean_folder detail {
	switch $detail {
	DELETE_CURRENT_RESULT -
	DELETE_CURRENT_WORKDIR -
	DELETE_CURRENT_EXCEPT_ORIGINAL -
	DELETE_CURRENT_ALL -
	DELETE_ALL_RESULT -
	DELETE_ALL_WORKDIR -
	DELETE_ALL_EXCEPT_ORIGINAL -
	DELETE_ALL {
		set reply [tk_dialog .foo [mc CONFIRM] "You choosed [mc $detail].\nis this right? this task is unrecovable." \
        warning 1 [mc YES] [mc NO]]
	}
	}
}

proc Tip_about {} {}