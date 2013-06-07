namespace eval ModApk {
	variable systemcompile {}

	set types [list \
		[list [mc {All readable file}] {.apk .jar}] \
		[list [mc {Apk file}]          {.apk}     ] \
		[list [mc {Jar file}]          {.jar}     ] \
		[list [mc {All file}]          {*}        ] \
	]

	proc Sox args {
		set tmpdir [file dirname [getVFile sox.exe]]
		getVFile zlib1.dll
		getVFile pthreadgc2.dll

		bgopen ::View::Print [getVFile sox.exe] {*}$args
	}

	foreach jarfile {apktool signapk} {

		proc $jarfile args "
			return \[Java -jar \[getVFile $jarfile.jar] {*}\$args]
		"

	}

	foreach exefile {fastboot optipng 7za aapt} {

		proc $exefile args "
			return \[bgopen ::View::Print \[getVFile $exefile.exe] {*}\$args]
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

		apktool d {*}$::config(decomTargetOpt) -f $cApp(path) $cApp(proj)
		7za -y x -o$cApp(proj) $cApp(path) META-INF -r
	}

	proc Compile apkPath {
		GetNativePathArray $apkPath cApp

		if ![file isdirectory $cApp(proj)] {
			tk_messageBox -message [mc {Please extract/decompile app first.}]\n -icon info -type ok
			return
		}

		if {[file extension $cApp(path)] == ".jar"} {
			::View::Print [mc {jar compiling...}]\n
			7za -y x -o$cApp(proj) $cApp(path) META-INF -r
		} else {
			::View::Print [mc {apk compiling...}]\n
		}

		if [apktool b -a [getVFile aapt.exe] $cApp(proj) $cApp(unsigned)] {
			::View::Print [mc {Compile failed. Task terminated.}]\n
			return
		}
		::View::Print [mc {Adjusting compressing level...}]\n
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

	proc {System compile} apkPath {
		variable systemcompile {
			foreach metafile {resources.arsc AndroidManifest.xml} {
				7za -y x -aoa -o[file nativename $cApp(proj)/temp] $cApp(path) $metafile
			}
		}
		Compile $apkPath
		set systemcompile {}
	}

	proc Zip apkPath {
		GetNativePathArray $apkPath cApp

		if ![file isdirectory $cApp(proj)] {
			tk_messageBox -message [mc {Please extract/decompile app first.}]\n -icon info -type ok
			return
		}

		::View::Print Compressing...
		file delete -- $cApp(unsigned)
		7za -y a -tzip -mx$::config(zlevel) $cApp(unsigned) $cApp(proj)\\*
	}

	proc {Install framework} {} {
		variable types

		set frameworks [tk_getOpenFile -filetypes $types -multiple 1 \
			-initialdir [file dirname $::vfsdir] -title [mc {Select framework file or folder}]]
		if {$frameworks != ""} {
			foreach framework $frameworks {apktool if $framework}
		}
	}

	proc Sign apkPath {
		GetNativePathArray $apkPath cApp

		if [signapk -w [getVFile testkey.x509.pem] [getVFile testkey.pk8] $cApp(unsigned) $cApp(signed)] {
			::View::Print "[mc {Signing failed}]: $cApp(name)\n"
		} {
			file delete -- $cApp(unsigned)
			::View::Print "[mc Signed]: $cApp(name)\n"
		}
	}

	proc Zipalign apkPath {
		GetNativePathArray $apkPath cApp

		foreach path [list $cApp(signed) $cApp(unsigned) $cApp(path)] {
			if [file exist $path] {
				if [catch {
					set alignedPath [AdaptPath [file dirname $path]/aligned_$cApp(name)]
					exec [getVFile zipalign.exe] -f 4 $path $alignedPath
					file rename -force -- $alignedPath $path
				}] {
					::View::Print "[mc {Zipalign failed}]: $cApp(name)\n"
				} {
					::View::Print "[mc Zipaligned]: $cApp(name)\n"
				}
				break
			}
		}
	}

	proc {Explore project} apkPath {
		GetNativePathArray $apkPath cApp
		catch {exec explorer $cApp(proj)}
	}

	proc {Explore app dir} {} {
		set samplePath [lindex $::cAppPaths 0]
		catch {exec explorer [AdaptPath [file dirname $samplePath]]}
	}

	proc {Optimize png} apkPath {
		GetNativePathArray $apkPath cApp

		foreach pngfile [scan_dir $cApp(proj) *.png] {
			optipng $pngfile
		}

	}

	proc {Recompress ogg} apkPath {
		GetNativePathArray $apkPath cApp

		foreach ogg [scan_dir $cApp(proj) *.ogg] {
			set subpath [file nativename [string map [list [file dirname $cApp(proj)]/ ""] [file normalize $ogg]]]
			::View::Print "[mc Processing]$subpath\n"
			Sox  $ogg -C 0 $ogg
		}
	}

	proc {Switch sign} apkPath {
		GetNativePathArray $apkPath cApp
		if ![file exist $cApp(proj) {Extract $apkPath}
		if [file exist $cApp(proj)/META-INF] {
			file delete -force -- $cApp(proj)/META-INF
		} {
			7za -y x -o$cApp(proj) $cApp(path) META-INF -r
		}
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
			::View::Print "[mc Delete]: [AdaptPath $item]\n"
			file delete -force -- $item
		}
	}

	proc {Check update} {} {
		if [::View::running_other_task?] return

		set ::currentOp "update"
		set exit {set ::currentOp ""; return 0}
		set updateFileSignature {Apkz Update Information File}

		::View::Print [mc {Checking update..}]\n

		::http::config -useragent "Mozilla/5.0 (compatible; MSIE 10.0; $::tcl_platform(os) $::tcl_platform(osVersion);)"
		set updateinfo [httpcopy http://db.tt/v7qgMqqN]
		if ![string match $updateFileSignature* $updateinfo] {
			::View::Print [mc {Update info not found. Please check website.}]\n
			eval $exit
		}

		set updateinfo [string map [list $updateFileSignature {}] $updateinfo]

		set ret [catch {
			foreach ver [dict keys $updateinfo] {
				if {[package vcompare $ver $::apkzver] != 1} continue

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

			set latestver 0
			foreach ver [dict keys $updateinfo] {
				if {[package vcompare $ver $latestver] == 1} {

					set latestver $ver
				}
			}
			if {$latestver == $::apkzver} {
				::View::Print [mc {There are no updates available.}]\n
				return
			}

			set ans [tk_dialog .updateDlg [mc {New version found!}] \
				"[mc {Do you want to update?}]\n\n[string trim $changelog]" \
				{} [mc Yes] [mc Yes] [mc No]]
			if {$ans == 1} $exit

			if [dict exist $updateinfo $latestver filename] {
				set filename [dict get $updateinfo $latestver filename]
			} {
				set filename {Apkzipper.exe}
			}
			set updatefile [AdaptPath [file normalize "$::vfsdir/../$filename"]]

			foreach downloadurl [dict get $updateinfo $latestver downloadurl] {
				set success [catch {httpcopy $downloadurl $updatefile}]
				if {$success == 0} {
					catch {exec [auto_execok explorer.exe] [file nativename [file dirname $updatefile]]}
					break
				}
			}
		} {} errinfo]

		if {$ret == 1} {
			::View::Print "[mc ERROR] $ret: [dict get $errinfo -errorinfo]\n"
		}
		eval $exit
	}

}
