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

	puts $::wrInfo [mc {Extracting...}]
	if [file exist $cApp(proj)] {
		file delete -force -- $cApp(proj)
	}
	7za x -y -o$cApp(proj) $cApp(path)
	puts $::wrInfo [mc {Extraction finished.}]
}

plugin Decompile apkPath {
	getNativePathArray $apkPath cApp

	puts $::wrInfo [mc {Decompiling...}]
	apktool d {*}$::config(decomTargetOpt) -f $cApp(path) $cApp(proj)
	7za x -y -o$cApp(proj) $cApp(path) META-INF -r
	puts $::wrInfo [mc {Successfully decompiled.}]
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
	if {[info coroutine] eq {compileRoutine}} yield

	# 원본사인 강제주입. 실행은 되도 앱 크래시의 요인이 될 수 있다.
	if [file isdirectory $cApp(proj)/META-INF] {
		file copy -force -- $cApp(proj)/META-INF $cApp(proj)/temp/META-INF
	}
	file delete -- $cApp(unsigned)
	7za a -y -tzip -mx$::config(zlevel) $cApp(unsigned) $cApp(proj)\\temp\\*
	file delete -force -- $cApp(proj)\\temp
	
	puts $::wrInfo [mc {Sucessfully compiled.}]
}

plugin {System compile} apkPath {
	coroutine compileRoutine Compile business $apkPath
	
	puts $::wrDebug [mc {Restoring original resource and manifest...}]
	
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

	puts $::wrInfo [mc Compressing...]
	file delete -- $cApp(unsigned)
	7za a -y -tzip -mx$::config(zlevel) $cApp(unsigned) $cApp(proj)\\*
	puts $::wrInfo [mc Compressed.]
}

plugin {Install framework} {} {
	set frameworks [dlgSelectAppFiles [mc {Select framework file or folder}]]

	if {$frameworks != ""} {
		puts $::wrInfo [mc {Framework installing...}]
		foreach framework $frameworks {apktool if $framework}
		puts $::wrInfo [mc {Framework installed.}]
	}
}

plugin Sign apkPath {
	getNativePathArray $apkPath cApp

	if [signapk -w [getVFile testkey.x509.pem] [getVFile testkey.pk8] $cApp(unsigned) $cApp(signed)] {
		puts $::wrError [mc {Signing failed: %s} $cApp(name)]
	} {
		file delete -- $cApp(unsigned)
		puts $::wrInfo [mc {Signed: %s} $cApp(name)]
	}
}

plugin Zipalign apkPath {
	getNativePathArray $apkPath cApp

	foreach path [list $cApp(signed) $cApp(unsigned)] {
		if [file exist $path] {
			puts $::wrInfo [mc {Zipaligning...}]
			set alignedPath [AdaptPath [file dirname $path]/aligned_$cApp(name)]
			zipalign -f 4 $path $alignedPath
			file rename -force -- $alignedPath $path
			puts $::wrInfo [mc {Zipaligned: %s} $path]
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

	puts $::wrInfo [mc {Picture optimizing...}]
	foreach pngfile [scan_dir $cApp(proj) *.png] {
		optipng $pngfile
	}
	puts $::wrInfo [mc {Picture optimization finished.}]
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
		lappend ret {*}[glob -nocomplain -directory [file dirname $path] [file tail $path]]
	}
	return $ret
}

proc ListAndConfirmDlg {msg cols items} {
	set top [toplevel .deleteConfirm[generateID]]
	wm title $top [mc {Confirm}]
	
	set msglbl [ttk::label $top.msg -text $msg]
	set scroll [ttk::scrollbar $top.scroll -command "$top.list yview"]
	set footer [ttk::frame $top.foot]
	set yes [ttk::button $footer.yes -text [mc {Yes}] -command "[info coroutine] true"]
	set no  [ttk::button $footer.no  -text [mc {No}] -command [list destroy $top]]
	set listbx [ttk::treeview $top.list -yscroll "$scroll set" -show headings -column $cols]
	foreach col $cols {
		$listbx heading $col -text $col -anchor w
		$listbx column $col -width [expr [font measure TkDefaultFont $col] + 5]
	}

	set numCol [llength $cols]
	set numRow [expr [llength $items] / $numCol]
	for {set i 0} {$i < $numRow} {incr i} {
		set row [lrange $items [expr $i * $numCol] [expr ($i + 1) * $numCol - 1]]
		$listbx insert {} end -values $row
		foreach col [$listbx cget -columns] item $row {
			set len [font measure TkDefaultFont "$item  "]
			if {[$listbx column $col -width] < $len} {
				$listbx column $col -width $len
			}
		}
	}

	pack $msglbl -side top
	pack $yes -side left -fill x
	pack $no -side right -fill x
	pack $footer -side bottom
	pack $scroll -side right -fill y
	pack $listbx -side left -expand 1 -fill both
	
	bind $top <Escape> [list destroy $top]
	bindtags $top onDestroy$top
	bind onDestroy$top <Destroy> "[info coroutine] false"

	raise $top
	focus $no

	set ret [yield]

	if [winfo exists $top] {
		bind onDestroy$top <Destroy> {}
		destroy $top
	}
	return $ret
}

proc {Clean folder} detail {
	set target {}
	if [string match {Delete current*} $detail] {
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
			}
		}
	}

	set modDir $::exeDir/modding
	switch $detail {
		{Delete all result}				{set target [globFilter $modDir/signed_*.apk $modDir/unsigned_*.apk]}
		{Delete all workdir}			{set target [globFilter $::exeDir/projects/*]}
		{Delete all except original}	{set target [globFilter $modDir/signed_*.apk $modDir/unsigned_*.apk $::exeDir/projects/*]}
		{Delete all}					{set target [globFilter $modDir/*.apk $::exeDir/projects/*]}
	}

	if [llength $target] {
		foreach item $target {
			lappend listItem [AdaptPath $item]
			if [file isdirectory $item] {
				lappend listItem [mc (folder)]
			} {
				lappend listItem {}
			}
		}
		set confirm [ListAndConfirmDlg {Are you sure delete?} \
			[list [mc Path] [mc {Is directory?}]] $listItem]
		if !$confirm return
	}

	if [catch {package require twapi_shell}] {
		set delete {file delete -force --}
	} {
		set delete {twapi::recycle_file}
	}
	
	set count 0
	foreach {path tag} $listItem {
		puts $::wrInfo "[mc Delete]: $path $tag"
		{*}$delete $item
		incr count
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
	puts $::wrInfo [mc {Converting dex to jar...}]
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
