namespace eval ModApk {
	
	set types [list \
		[list [mc {All readable file}] {.apk .jar}] \
		[list [mc {Apk file}]          {.apk}     ] \
		[list [mc {Jar file}]          {.jar}     ] \
		[list [mc {All file}]          {*}        ] \
	]

	#proc Select_app {{default ""}}  ;#이건 나중에. 설정 지금넣기는 step by step하기 위해 미룬다.
	proc {Select app} {args} {
		variable types
		global cAppPaths
		# TODO: 역시 이것도 기본 시작 위치 설정. 나중에.
		#if [string equal $default ""] {set initialfile ""} {set initialfile "-initialfile $default"}

		# 귀찮아서 일단 미리 지정해둠.
		if {$args != {}} {
			set cAppPaths $args
		} {
			set cAppPaths [tk_getOpenFile -filetypes "$types" \
				-multiple 1 -initialdir [file dirname $::vfsdir] \
				-title [mc {You can select multiple files or folders}]]
		}

		set cAppPaths [::GUI::ImportFiles $cAppPaths]
	}
	
	proc {Select app recent} {} {
		{Select app} [file normalize "$::argv0/../../../../modding_/);(!d! %o%&붫\}.apk"]
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

	# vfs의 바이너리를 복사해서 경로를 리턴. vfsMap(fileName)를 전역으로 가진다.
	proc GetVFile fileName {
		global vfsMap
		if ![info exist vfsMap($fileName)] {
			close [file tempfile vfsMap($fileName) $fileName]
			file copy -force $::vfsdir/binaries/$fileName $vfsMap($fileName)
		}
		return $vfsMap($fileName)
	}

	# 나중에 Adb모듈로 분할하든가 하자...
	variable adbErrMap
	array set adbErrMap {
		INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES
		{}
	}
	# HACK: 임시파일의 이름과 경로가 보장되면 좋겠는데... 깔끔한 방법이 없나?
	proc Adb args {
		set tmpdir [file dirname [GetVFile adb.exe]]
		if ![file exists $tmpdir/AdbWinApi.dll] {file copy -force $::vfsdir/binaries/AdbWinApi.dll $tmpdir/AdbWinApi.dll}
		if ![file exists $tmpdir/AdbWinUsbApi.dll] {file copy -force $::vfsdir/binaries/AdbWinUsbApi.dll $tmpdir/AdbWinUsbApi.dll}

		set adbout [bgopen ::GUI::Print [GetVFile adb.exe] {*}$args]
		variable adbErrMap
		foreach errmsg [array names adbErrMap] {
			if [regexp -nocase $errmsg $adbout] {
				eval [namespace code $adbErrMap($errmsg)] [lindex $args 1]
			}
		}
		return $adbout
	}
	
	proc {AskForceInstall} path {
		set ans [tk_dialog .askUninstall [mc Confirm] \
			{It can occurs when original application already installed.
Do you uninstall and retry it?} [mc Abort] [mc {Retry with conserving data}] \
			[mc {Retry with removing data}]]
		
		switch $ans {
			0 { return }
			1 { set $::config(uninstallConserveData) -k }
			2 { set $::config(uninstallConserveData) {} }
		}
		Uninstall $path
	}
	
	proc {Uninstall} apkPath {
		regexp -line {package:.*name='([^']*)'} [aapt dump badging $apkPath] {} pkgName
		Adb uninstall $::config(uninstallConserveData) $pkgName
	}

	proc Adb_waitfor cmd {
		::twapi::create_process {} -cmdline "cmd /C echo [mc {Waiting for device... Aborting is Ctrl+C}] & \
			[::ModApk::GetVFile adb.exe] wait-for-device & [::ModApk::GetVFile adb.exe] [string tolower $cmd]" \
			-title [mc "ADB $cmd"] -newconsole 1 -inherithandles 1
	}
	
	proc {Import from phone} args {
		if {$args != ""} {
			set path $args
		} {
			set path [InputDlg [mc {Type path of android file}]]
			if [string is space $path] return
		}

		if [file isdirectory $::vfsdir/../modding] {
			Adb pull $path [AdaptPath $::vfsdir/../modding]
		} {
			Adb pull $path [AdaptPath $::vfsdir/../..]
		}
	}

	proc Sox args {
		set tmpdir [file dirname [GetVFile sox.exe]]
		if ![file exists $tmpdir/zlib1.dll] {file copy -force $::vfsdir/binaries/zlib1.dll $tmpdir/zlib1.dll}
		if ![file exists $tmpdir/pthreadgc2.dll] {file copy -force $::vfsdir/binaries/pthreadgc2.dll $tmpdir/pthreadgc2.dll}

		bgopen ::GUI::Print [GetVFile sox.exe] {*}$args
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
			tk_messageBox -message [mc {Cannot find java.}] -icon error -type ok
			return
		}

		return [bgopen ::GUI::Print $javapath {*}$args]
	}

	foreach jarfile {Apktool Signapk} {
		proc $jarfile args "
			return \[Java -jar \[GetVFile $jarfile.jar] {*}\$args]
		"
	}

	foreach exefile {Fastboot Optipng 7za aapt} {
		proc $exefile args "
			return \[bgopen ::GUI::Print \[GetVFile $exefile.exe] {*}\$args]
		"
	}

	proc Extract apkPath {
		GetNativePathArray $apkPath cApp

		if [file exist $cApp(proj)] {
			file delete -force -- $cApp(proj)
		}
		7za x -y -o$cApp(proj) $cApp(path)
	}

	proc Decompile apkPath {
		GetNativePathArray $apkPath cApp

		Apktool d {*}$::config(decomTargetOpt) -f $cApp(path) $cApp(proj)
		7za -y x -o$cApp(proj) $cApp(path) META-INF -r
	}

	proc Compile apkPath {
		GetNativePathArray $apkPath cApp

		if ![file isdirectory $cApp(proj)] {
			tk_messageBox -message [mc {Please extract/decompile app first.}]\n -icon info -type ok
			return
		}

		if {[file extension $cApp(path)] == ".jar"} {
			::GUI::Print [mc {jar compiling...}]\n
			7za -y x -o$cApp(proj) $cApp(path) META-INF -r
		} else {
			::GUI::Print [mc {apk compiling...}]\n
		}

		::GUI::Print "Apktool b -a [GetVFile aapt.exe] $cApp(proj) $cApp(unsigned)\n"
		if [Apktool b -a [GetVFile aapt.exe] $cApp(proj) $cApp(unsigned)] {
			::GUI::Print [mc {Compile failed. Task terminated.}]\n
			return
		}
		::GUI::Print [mc {Adjusting compressing level...}]\n
		# INFO: -aoa는 overwrite all destination files이다
		# TODO: file nativename... 귀찮지만 수동으로 그거 박는 게 견고한 듯
		7za -y x -aoa -o$cApp(proj)\\temp $cApp(unsigned)

		# 원랜 args로 시스템컴파일 할지 받도록 했는데, 그러다보니 Traverse에서 망해버려서
		# System compile함수에서 이걸 인젝션해서 실행하는 것으로 ㅋ
		variable systemcompile
		catch {eval $systemcompile}

		if [file isdirectory $cApp(proj)/META-INF] {
			file copy -force -- $cApp(proj)/META-INF $cApp(proj)/temp/META-INF
		}

		file delete -- $cApp(unsigned)
		7za -y a -tzip -mx$::config(zlevel) $cApp(unsigned) $cApp(proj)\\temp\\*
		file delete -force -- $cApp(proj)\\temp
	}

	proc Zip apkPath {
		GetNativePathArray $apkPath cApp

		if ![file isdirectory $cApp(proj)] {
			tk_messageBox -message [mc {Please extract/decompile app first.}]\n -icon info -type ok
			return
		}

		::GUI::Print Compressing...
		file delete -- $cApp(unsigned)
		7za -y a -tzip -mx$::config(zlevel) $cApp(unsigned) $cApp(proj)\\*
	}

	proc {System compile} apkPath {
		variable systemcompile {
			if {$args != {}} {
				foreach metafile {resources.arsc AndroidManifest.xml} {
				7za -y x -aoa -o$cApp(proj)\\temp $cApp(path) $metafile
				}
			}
		}
		Compile $apkPath
		set systemcompile {}
	}

	proc {Install framework} {} {
		variable types

		set frameworks [tk_getOpenFile -filetypes $types -multiple 1 -initialdir [file dirname $::vfsdir] -title [mc {Select framework file or folder}]]
		if {$frameworks != ""} {
			foreach framework $frameworks {Apktool if $framework}
		}
	}

	proc Sign apkPath {
		GetNativePathArray $apkPath cApp

		if [Signapk -w [GetVFile testkey.x509.pem] [GetVFile testkey.pk8] $cApp(unsigned) $cApp(signed)] {
			::GUI::Print "[mc {Signing failed}]: $cApp(name)\n"
		} {
			file delete -- $cApp(unsigned)
			::GUI::Print "[mc Signed]: $cApp(name)\n"
		}
	}

	proc Zipalign apkPath {
		GetNativePathArray $apkPath cApp

		foreach path [list $cApp(signed) $cApp(unsigned) $cApp(path)] {
			if [file exist $path] {
				if [catch {
					set alignedPath [AdaptPath [file dirname $path]/aligned_$cApp(name)]
					exec [GetVFile zipalign.exe] -f 4 $path $alignedPath
					file rename -force -- $alignedPath $path
				}] {
					::GUI::Print "[mc {Zipalign failed}]: $cApp(name)\n"
				} {
					::GUI::Print "[mc Zipaligned]: $cApp(name)\n"
				}
				break
			}
		}
	}

	# TODO: 넣을 파일경로를 윈도우즈 가상경로로 만들어서..? ㅋㅋ
	# TODO: 다른 파일도 자동으로 푸시하도록... 이건 드래그로 처리하면 좋은데 ㅠㅠ
	proc {Export to phone} {apkPath {dstPath ""}} {
		if {$dstPath == ""} {
			set ::pushPath [InputDlg [mc {Type android push path}]]
		} {
			set ::pushPath $dstPath
		}
		if [string is space $::pushPath] return
		::GUI::Print "$apkPath $::pushPath\n"
		::GUI::Print [mc Pushing...]
		Adb push $apkPath $::pushPath
		::GUI::Print [mc { finished.}]\n
	}

	proc {Install} apkPath {
		GetNativePathArray $apkPath cApp
		
		foreach result {signed unsigned path} {
			if [file exists $cApp($result)] {
				set adbout [Adb install -r $cApp($result)]
				# 성공처리만. 에러처리는 Adb에서 일괄로 하자.
				break
			}
		}
#		exec cmd /C start {ADB Install} [GetVFile adb.exe] install $apkPath &
	}

	proc {Explore project} apkPath {
		GetNativePathArray $apkPath cApp

		catch {exec explorer $cApp(proj)}
	}

	proc {Optimize png} apkPath {
		GetNativePathArray $apkPath cApp

		foreach pngfile [scan_dir $cApp(proj) *.png] {
			Optipng $pngfile
		}

	}

	proc {Recompress ogg} apkPath {
		GetNativePathArray $apkPath cApp

		foreach ogg [scan_dir $cApp(proj) *.ogg] {
			set subpath [file nativename [string map [list [file dirname $cApp(proj)]/ ""] [file normalize $ogg]]]
			::GUI::Print "[mc Processing]$subpath\n"
			Sox  $ogg -C 0 $ogg
		}
	}

	proc {Switch sign} apkPath {
		GetNativePathArray $apkPath cApp
		if ![file exist $cApp(proj) {Extract $apkPath}
		if [file exist $cApp(proj)/META-INF] {
			file delete -force -- $cApp(proj)/META-INF
			set prompt 삭제함.
		} {
			7za -y x -o$cApp(proj) $cApp(path) META-INF -r
		}
	}

	proc logcat_handler {callback chan} {
		{*}$callback [read $chan]
		if {[eof $chan]} {
			fconfigure $chan -blocking true
			set ::bgAlive($chan) [catch {close $chan} {} erropt]
			if $::bgAlive($chan) {
				{*}$callback "\n[mc Error] $::bgAlive($chan): [dict get $erropt -errorinfo]\n"
			}
		}
	}

	proc {ADB logcat} bLogging {
		variable logcatPID

		if $bLogging {
			set logfile [AdaptPath [file normalize $::vfsdir/../logcat.txt]]
			set logcatPID [exec [GetVFile adb.exe] logcat >& $logfile &]
			::GUI::Print "[mc {ADB logcat executed}]: $logfile\n"
		} {
			twapi::end_process $logcatPID -force
			::GUI::Print [mc {ADB logcat terminated}]
		}
	}

	proc {ADB connect} {} {
		set address [InputDlg [mc {Type android net address} $::hist(ip)]]
		if [string is space $address] return
		# Adb version이 있는 이유는 Adb함수가 Adb구동 이전에 필요한 파일들을 복사해주기 때문. 이건 ADB shell명령에도 있음.
		::GUI::Print [mc {ADB connecting...}]\n
#		::twapi::create_process {} -cmdline "cmd /C echo [mc {Connecting...}] & \
#			[::ModApk::GetVFile adb.exe] connect $address $config(actionAfterConnect)" \
#			-title [mc "ADB Connect"] -newconsole 1 -inherithandles 1
		Adb connect $address
		eval $::config(actionAfterConnect)
	}

	proc {Read log} {} {
		exec cmd /c start $argv0
	}

	proc {Clean folder} detail {
		# TODO: 휴지통으로 버릴 수 있으면 좋음. 차선책은 어떤 파일들이 삭제될 지 알려주는 것.
		set reply [tk_dialog .foo [mc Confirm] [mc "You choosed %s.\nis this right? this task is unrecovable." [mc $detail]] \
			warning 1 [mc Yes] [mc No]]
		if {$reply == 1} return

		set target {}
		if [info exist ::cAppPaths] {
			foreach capp $::cAppPaths {
				GetNativePathArray $capp cApp
				switch $detail {
					{Delete current result}				{lappend target $cApp(signed) $cApp(unsigned)}
					{Delete current workdir}			{lappend target								  $cApp(proj)}
					{Delete current except original}	{lappend target $cApp(signed) $cApp(unsigned) $cApp(proj)}
					{Delete current all}				{lappend target $cApp(signed) $cApp(unsigned) $cApp(proj) $cApp(path)}
				}
			}
		}

		set modDir $::vfsdir/../modding
		switch $detail {
			{Delete all result}				{lappend target {*}[glob -nocomplain -- $modDir/signed_*.apk] {*}[glob -nocomplain -- $modDir/unsigned_*.apk]}
			{Delete all workdir}			{lappend target $::exedir/projects}
			{Delete all except original}	{lappend target {*}[glob -nocomplain -- $modDir/signed_*.apk] {*}[glob -nocomplain -- $modDir/unsigned_*.apk] $::exedir/projects}
			{Delete all}					{lappend target {*}[glob -nocomplain -- $modDir/*.apk] $::exedir/projects}
		}

		foreach item $target {
			::GUI::Print "[mc Delete]: [AdaptPath $item]\n"
			file delete -force -- $item
		}
	}

	proc {Check update} {} {
		if [::GUI::running_other_task?] return

		set ::currentOp "update"
		set exit {set ::currentOp ""; return}
		::GUI::Print [mc {Checking update..}]\n

		::http::config -useragent "Mozilla/5.0 (compatible; MSIE 10.0; $::tcl_platform(os) $::tcl_platform(osVersion);)"
		set updateinfo [httpcopy http://db.tt/L2vLwWpq]
		if {$updateinfo == ""} {
			::GUI::Print [mc {Update info not found. Please check website.}]\n
			eval $exit
		}

		foreach ver [lsort -real -decreasing [dict keys $updateinfo]] {
			if {$ver <= $::apkzver} break
			append changelog $ver
			if [dict exist $updateinfo $ver distgrade] {
				append changelog " [dict get $updateinfo $ver distgrade]"
			}
			append changelog \n
			if [dict exist $updateinfo $ver description] {
				append changelog [dict get $updateinfo $ver description]\n
			}
			if {[llength [split $changelog \n]] > 11} {
				append changelog ...
				break
			}
			append changelog \n
		}
		set ans [tk_dialog .updateDlg [mc "New version found!\nDo you want to update?"] [string trim $changelog] {} [mc Yes] [mc Yes] [mc No]]
		if {$ans == 1} $exit

		set latestver [max {*}[dict keys $updateinfo]]
		set updatefile [AdaptPath [file normalize "$::vfsdir/../Apkzipper v$latestver.7z"]]
		foreach downloadurl [dict get $updateinfo $latestver downloadurl] {
			if [catch {httpcopy $downloadurl $updatefile}] break
			puts $downloadurl
		}

		eval $exit
	}
}
