foreach jarfile {apktool signapk baksmali smali} {
	proc $jarfile args [format {
		return [Java -jar [getVFile %s.jar] {*}$args]
	} $jarfile]
}

foreach exefile {fastboot optipng 7za aapt zipalign jd-gui} {
	proc $exefile args [format {
		return [bgopen ::View::Print [getVFile %s.exe] {*}$args]
	} $exefile]
}

plugin Extract apkPath {
	getNativePathArray $apkPath cApp

	if [file exist $cApp(proj)] {
		file delete -force -- $cApp(proj)
	}
	7za x -y -o$cApp(proj) $cApp(path)
}

plugin Decompile apkPath {
	getNativePathArray $apkPath cApp

	apktool d {*}$::config(decomTargetOpt) -f $cApp(path) $cApp(proj)
	7za x -y -o$cApp(proj) $cApp(path) META-INF -r
}

plugin Compile apkPath {
	getNativePathArray $apkPath cApp

	if ![file isdirectory $cApp(proj)] {
		tk_messageBox -message [mc {Please extract/decompile app first.}]\n -icon info -type ok
		return
	}

	if {[file extension $cApp(path)] == ".jar"} {
		::View::Print [mc {jar compiling...}]\n
		7za x -y -o$cApp(proj) $cApp(path) META-INF -r
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
	7za x -y -aoa -o$cApp(proj)\\temp $cApp(unsigned)

	# System compile일 경우 별도의 작업
	if {[info coroutine] ne {}} yield

	# 원본사인 강제주입. 실행은 되도 앱 크래시의 요인이 될 수 있다.
	if [file isdirectory $cApp(proj)/META-INF] {
		file copy -force -- $cApp(proj)/META-INF $cApp(proj)/temp/META-INF
	}
	file delete -- $cApp(unsigned)
	7za a -y -tzip -mx$::config(zlevel) $cApp(unsigned) $cApp(proj)\\temp\\*
	file delete -force -- $cApp(proj)\\temp
}

plugin {System compile} apkPath {
	coroutine compileRoutine Compile business $apkPath
	getNativePathArray $apkPath cApp
	foreach metafile {resources.arsc AndroidManifest.xml} {
		7za x -y -aoa -o[file nativename $cApp(proj)/temp] $cApp(path) $metafile
	}
	compileRoutine
}

plugin Zip apkPath {
	getNativePathArray $apkPath cApp

	if ![file isdirectory $cApp(proj)] {
		tk_messageBox -message [mc {Please extract/decompile app first.}]\n -icon info -type ok
		return
	}

	::View::Print Compressing...
	file delete -- $cApp(unsigned)
	7za a -y -tzip -mx$::config(zlevel) $cApp(unsigned) $cApp(proj)\\*
}

plugin {Install framework} {} {
	set frameworks [dlgSelectAppFiles [mc {Select framework file or folder}]]

	if {$frameworks != ""} {
		foreach framework $frameworks {apktool if $framework}
	}
}

plugin Sign apkPath {
	getNativePathArray $apkPath cApp

	if [signapk -w [getVFile testkey.x509.pem] [getVFile testkey.pk8] $cApp(unsigned) $cApp(signed)] {
		::View::Print "[mc {Signing failed}]: $cApp(name)\n"
	} {
		file delete -- $cApp(unsigned)
		::View::Print "[mc Signed]: $cApp(name)\n"
	}
}

plugin Zipalign apkPath {
	getNativePathArray $apkPath cApp

	foreach path [list $cApp(signed) $cApp(unsigned)] {
		if [file exist $path] {
			set alignedPath [AdaptPath [file dirname $path]/aligned_$cApp(name)]
			zipalign -f 4 $path $alignedPath
			file rename -force -- $alignedPath $path
			::View::Print "[mc Zipaligned]: $path\n"
			break
		}
	}
}

plugin {Explore project} apkPath {
	getNativePathArray $apkPath cApp
	catch {exec explorer $cApp(proj)}
}

plugin {Explore app dir} {} {
	set samplePath [lindex $::cAppPaths 0]
	catch {exec explorer [AdaptPath [file dirname $samplePath]]}
}

plugin {Optimize png} apkPath {
	getNativePathArray $apkPath cApp

	foreach pngfile [scan_dir $cApp(proj) *.png] {
		optipng $pngfile
	}

}

plugin {Switch sign} apkPath {
	getNativePathArray $apkPath cApp
	if ![file exist $cApp(proj) {Extract $apkPath}
		if [file exist $cApp(proj)/META-INF] {
			file delete -force -- $cApp(proj)/META-INF
		} {
			7za x -y -o$cApp(proj) $cApp(path) META-INF -r
		}
	}

plugin {Read log} {} {
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
			getNativePathArray $capp cApp
			switch $detail {
				{Delete current result}				{lappend target $cApp(signed) $cApp(unsigned)}
				{Delete current workdir}			{lappend target								  $cApp(proj)}
				{Delete current except original}	{lappend target $cApp(signed) $cApp(unsigned) $cApp(proj)}
				{Delete current all}				{lappend target $cApp(signed) $cApp(unsigned) $cApp(proj) $cApp(path)}
			}
		}
	}

	set modDir $::exedir/modding
	switch $detail {
		{Delete all result}				{lappend target {*}[glob -nocomplain -- $modDir/signed_*.apk] {*}[glob -nocomplain -- $modDir/unsigned_*.apk]}
		{Delete all workdir}			{lappend target $::exedir/projects}
		{Delete all except original}	{lappend target {*}[glob -nocomplain -- $modDir/signed_*.apk] {*}[glob -nocomplain -- $modDir/unsigned_*.apk] $::exedir/projects}
		{Delete all}					{lappend target {*}[glob -nocomplain -- $modDir/*.apk] $::exedir/projects}
	}

	set count 0
	foreach item $target {
		if [file exist $item] {
			if [file isdirectory $item] {
				set suffix [mc (folder)]
			} {
				set suffix {}
			}
			::View::Print "[mc Delete]: [AdaptPath $item] $suffix\n"
			file delete -force -- $item
			incr count
		}
		update idletasks
	}
	::View::Print [mc {%d items are deleted.} $count]\n
}

plugin {Check update} {} {
#	if [::View::running_other_task?] return

	set ::currentOp "update"
	set exit {set ::currentOp ""; return}
	set updateFileSignature {Apkz Update Information File}

	::View::Print [mc {Checking update..}]\n

	set updateinfo [httpcopy http://db.tt/v7qgMqqN]
	if ![string match $updateFileSignature* $updateinfo] {
		::View::Print [mc {Update info not found. Please check website.}]\n
		eval $exit
	}

	set updateinfo [string map [list $updateFileSignature {}] $updateinfo]

	set changelog {}
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

		if {[package vcompare $latestver $::apkzver] != 1} {
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
		set updatefile [AdaptPath [file normalize "$::exedir/$filename"]]

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

plugin {Deodex} {apkPath} {
	getNativePathArray $apkPath cApp
	
	set odex [file rootname $cApp(path)].odex
	set dex [file nativename $cApp(proj)/classes.dex]
	set dexDir [file rootname $cApp(proj)].odex/
	ensureFiles $odex
	
	::View::Print deodexing...\n
	file delete -force $dexDir $dex
	set apkDir [file dirname $cApp(path)]
	baksmali -d $apkDir/framework -d $apkDir -x $odex -o $dexDir
	::View::Print Complete\n
}

plugin {Odex} {apkPath} {
	getNativePathArray $apkPath cApp
	
	set dexDir [file rootname $cApp(proj)].odex
	set dex [file nativename $cApp(proj)/classes.dex]
	
	::View::Print Odexing...\n
	smali $dexDir -o $dex
	::View::Print Complete\n
}

proc dex2jar {dex jar} {
	set dex2jar [getVFile dex2jar]
	Java -cp $dex2jar/* {com.googlecode.dex2jar.tools.Dex2jarCmd} -f -o $jar $dex
}

proc dex2jd {dex} {
	set jar [file rootname $tmpdex].jar
	dex2jar $tmpdex $jar
	exec [getVFile jd-gui.exe] $jar &
	return
}

plugin {View source} {apkPath} {
	getNativePathArray $apkPath cApp

	set tmpdex [file rootname $cApp(proj)].dex
	foreach appIdx {path unsigned signed} {
		if [file exist $cApp($appIdx)] {
			7za e -y -aoa $cApp(path) -o$tmpdex classes.dex
		}
	}
	if [rdbleFile $tmpdex] {
		dex2jd $tmpdex
		return
	}
	
	set odex [file rootname $cApp(path)].odex
	if [rdbleFile $odex] {
		::Deodex business $apkPath
		::Odex business $apkPath
		dex2jd $cApp(proj)/classes.dex
		return
	}
	
	::View::Print [mc {Cannot find classes.dex}]\n
}
