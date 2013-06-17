foreach jarfile {signapk baksmali smali} {
	eval [format {
		proc %1$s args {
			return [Java -jar [getVFile %1$s.jar] {*}$args]
	}} $jarfile]
}

proc apktool args {
	set predErrBody {
		my variable hasErr
		if ![info exist hasErr] {
			set hasErr false
		}
		foreach line [split $data \n] {
			if [string match Excep* $line]||[string match -nocase error]||$hasErr {
				puts -nonewline $::_wrError $line
				set hasErr true
			} elseif [string match W:* $line] {
				puts -nonewline $::wrWarning $line
			} {
				puts -nonewline $::wrDebug $line
			}
		}
		return [string bytelength $data] 
	}
	try {
		set ::_wrError $::wrError
		set ::wrError [chan create write [InterChan new $predErrBody]]
		fconfigure $::wrError -blocking false -buffering none
		set returnInfo [Java -jar [getVFile apktool.jar] {*}$args]
	} finally {
		close $::wrError
		set ::wrError $::_wrError
		unset ::_wrError
		if [info exist returnInfo] {
			return $returnInfo
		}
	}
}

foreach exefile {fastboot optipng 7za aapt zipalign jd-gui} {
	eval [format {
		proc %1$s args {
			return [bgopen [list puts $::wrDebug] [getVFile %1$s.exe] {*}$args]
	}} $exefile]
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
		puts $::wrInfo [mc {jar compiling...}]
		7za x -y -o$cApp(proj) $cApp(path) META-INF -r
	} else {
		puts $::wrInfo [mc {apk compiling...}]
	}

	if [apktool b -a [getVFile aapt.exe] $cApp(proj) $cApp(unsigned)] {
		puts $::wrError [mc {Compile failed. Task terminated.}]
		return
	}
	puts $::wrDebug [mc {Adjusting compressing level...}]
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

	puts $::wrInfo Compressing...
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
		puts $::wrError "[mc {Signing failed}]: $cApp(name)\n"
	} {
		file delete -- $cApp(unsigned)
		puts $::wrInfo "[mc Signed]: $cApp(name)\n"
	}
}

plugin Zipalign apkPath {
	getNativePathArray $apkPath cApp

	foreach path [list $cApp(signed) $cApp(unsigned)] {
		if [file exist $path] {
			set alignedPath [AdaptPath [file dirname $path]/aligned_$cApp(name)]
			zipalign -f 4 $path $alignedPath
			file rename -force -- $alignedPath $path
			puts $::wrInfo "[mc Zipaligned]: $path\n"
			break
		}
	}
}

plugin {Explore project} apkPath {
	getNativePathArray $apkPath cApp
	catch {exec explorer $cApp(proj)}
}

plugin {Explore app dir} {} {
	set primaryAppDir [lindex $::cAppPaths 0]
	catch {exec explorer [AdaptPath [file dirname $primaryAppDir]]}
}

plugin {Explore dex dir} apkPath {
	getNativePathArray $apkPath cApp
	set dexDir [file rootname $cApp(proj)].odex
	if [file isdirectory $dexDir] {
		catch {exec explorer $dexDir}
	}
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

proc globFilter {args} {
	set ret {}
	foreach path $args {
		set ret [concat $ret [glob -nocomplain -path $path *]]
	}
	return $ret
}

proc ListAndConfirmDlg {msg args} {
	set top [toplevel .tlConfirm#[expr int(rand() * 10**9)]]
	wm title $top [mc {Confirm}]
	
	set msglbl [ttk::label $top.msg -text $msg]
	set scroll [ttk::scrollbar $top.scroll -command "$top.list yview"]
	set listbx [ttk::listbox $top.list -yscroll "$scroll set" -setgrid 1 -height 12]
	$listbx insert 0 {*}$args

	pack $msglbl -side top
	pack $scroll -side right -fill y
	pack $listbx -side left -expand 1 -fill both
}

proc {Clean folder} detail {
	# TODO: 휴지통으로 버릴 수 있으면 좋음. 차선책은 어떤 파일들이 삭제될 지 알려주는 것.
#	set reply [tk_dialog .foo [mc Confirm] [mc "You choosed %s.\nis this right? this task is unrecovable." [mc $detail]] \
		warning 1 [mc Yes] [mc No]]
#	if {$reply == 1} return

	set target {}
	if [info exist ::cAppPaths] {
		foreach capp $::cAppPaths {
			getNativePathArray $capp cApp
			set result [globFilter $cApp(signed) $cApp(unsigned)]
			set proj [globFilter [file rootname $cApp(proj)].*]
			set path [globFilter $cApp(path)]
			switch $detail {
				{Delete current result}				{set target [concat $target $result]}
				{Delete current workdir}			{set target [concat $target $proj]}
				{Delete current except original}	{set target [concat $target $result $proj]}
				{Delete current all}				{set target [concat $target $result $proj $path]}
#				{Delete current result}				{lappend target }
#				{Delete current workdir}			{lappend target								  $cApp(proj)}
#				{Delete current except original}	{lappend target $cApp(signed) $cApp(unsigned) $cApp(proj)}
#				{Delete current all}				{lappend target $cApp(signed) $cApp(unsigned) $cApp(proj) $cApp(path)}
			}
		}
	}

	set modDir $::exeDir/modding
	switch $detail {
		{Delete all result}				{lappend target {*}[glob -nocomplain -- $modDir/signed_*.apk] {*}[glob -nocomplain -- $modDir/unsigned_*.apk]}
		{Delete all workdir}			{lappend target {*}[glob -nocomplain == $::exeDir/projects/*}
		{Delete all except original}	{lappend target {*}[glob -nocomplain -- $modDir/signed_*.apk] {*}[glob -nocomplain -- $modDir/unsigned_*.apk] $::exeDir/projects}
		{Delete all}					{lappend target {*}[glob -nocomplain -- $modDir/*.apk] $::exeDir/projects}
	}

	set count 0
	foreach item $target {
		if [file exist $item] {
			if [file isdirectory $item] {
				set suffix [mc (folder)]
			} {
				set suffix {}
			}
			puts $::wrInfo "[mc Delete]: [AdaptPath $item] $suffix\n"
			file delete -force -- $item
			incr count
		}
		update idletasks
	}
	puts $::wrInfo [mc {%d items are deleted.} $count]
}

plugin {Check update} {} {
#	if [::View::running_other_task?] return

	set ::currentOp "update"
	set exit {set ::currentOp ""; return}
	set updateFileSignature {Apkz Update Information File}

	puts $::wrInfo [mc {Checking update..}]

	set updateinfo [httpcopy http://db.tt/v7qgMqqN]
	if ![string match $updateFileSignature* $updateinfo] {
		puts $::wrInfo [mc {Update info not found. Please check website.}]
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
			puts $::wrInfo [mc {There are no updates available.}]
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
		set updatefile [AdaptPath [file normalize "$::exeDir/$filename"]]

		foreach downloadurl [dict get $updateinfo $latestver downloadurl] {
			set success [catch {httpcopy $downloadurl $updatefile}]
			if {$success == 0} {
				catch {exec [auto_execok explorer.exe] [file nativename [file dirname $updatefile]]}
				break
			}
		}
	} {} errinfo]

	if {$ret == 1} {
		puts $::wrError "[mc ERROR] $ret: [dict get $errinfo -errorinfo]\n"
	}
	eval $exit
}

plugin {Deodex} {apkPath} {
	getNativePathArray $apkPath cApp
	
	set odex [file rootname $cApp(path)].odex
	set dex [file nativename $cApp(proj)/classes.dex]
	set dexDir [file rootname $cApp(proj)].odex/
	ensureFiles $odex
	
	puts -nonewline $::wrInfo [mc {Deodexing...}]
	file delete -force $dexDir $dex
	set apkDir [file dirname $cApp(path)]
	baksmali -d $apkDir/framework -d $apkDir -x $odex -o $dexDir
	puts $::wrInfo [mc { Complete.}]
}

plugin {Dex} {apkPath} {
	getNativePathArray $apkPath cApp
	
	set dexDir [file rootname $cApp(proj)].odex
	set dex [file nativename $cApp(proj)/classes.dex]
	
	puts $::wrInfo [mc {Dexing... }]
	smali $dexDir -o $dex
	puts $::wrInfo [mc { Complete.}]
}

proc dex2jar {dex jar} {
	set dex2jar [getVFile dex2jar]
	Java -cp $dex2jar/* {com.googlecode.dex2jar.tools.Dex2jarCmd} -f -o $jar $dex
}

proc dex2jd {dex} {
	set jar [file rootname $dex].jar
	dex2jar $dex $jar
	exec [getVFile jd-gui.exe] $jar &
}

plugin {View java source} {apkPath} {
	getNativePathArray $apkPath cApp

	set tmpdex [file rootname $cApp(proj)].dex
	foreach appIdx {path unsigned signed} {
		if [file exist $cApp($appIdx)] {
			7za e -y -aoa $cApp($appIdx) -o$tmpdex classes.dex
		}
	}
	if [rdbleFile $tmpdex/classes.dex] {
		dex2jd $tmpdex/classes.dex
		return
	}
	
	set odex [file rootname $cApp(path)].odex
	if [rdbleFile $odex] {
		::Deodex business $apkPath
		::Dex business $apkPath
		dex2jd $cApp(proj)/classes.dex
		return
	}
	
	puts $::wrError [mc {Cannot find classes.dex}]
}
