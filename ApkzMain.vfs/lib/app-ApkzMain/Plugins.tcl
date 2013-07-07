foreach jarfile {signapk baksmali smali} {
	eval [format {
		proc %1$s args {
			return [Java -jar [getVFile %1$s.jar] {*}$args]
	}} $jarfile]
}

proc apktool args {
	set ::hasErr false
	proc pred {chan} {
		set line [gets $chan]
		if [string match Excep* $line]||[string match -nocase error]||$::hasErr {
			puts $::wrError $line
			set ::hasErr true
		} elseif [string match W:* $line] {
			puts $::wrWarning $line
		} {
			puts $::wrDebug $line
		}
	}
	set result [tcl::chan::fifo]
	chan configure $result -blocking false -buffering line
	chan event $result readable [list pred $result]
	set exitcode [bgopen -chan $result [Java] -jar [getVFile apktool.jar] {*}$args]
	close $result
	return $exitcode
}

foreach exefile {fastboot 7za aapt zipalign jd-gui} {
	eval [format {
		proc %1$s args {
			return [bgopen [getVFile %1$s.exe] {*}$args]
	}} $exefile]
}

proc predPNGout {chan} {
	set data [read $chan]
	puts -nonewline $::wrDebug $data
}

proc optipng args {
	set outchan [tcl::chan::fifo]
	chan configure $outchan -blocking false -buffering none
	chan event $outchan readable [list predPNGout $outchan]
#	bgopen -chan $outchan [getVFile optipng.exe] {*}$args
	lassign [chan pipe] r w
	chan configure $r -blocking false -buffering none
	chan configure $w -blocking false -buffering none
	chan event $r readable "puts -nonewline $outchan \[read $r]"
	return [exec -- [getVFile optipng.exe] {*}$args >@ $w 2>@ $w &]
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

	apktool b -a [getVFile aapt.exe] $cApp(proj) $cApp(unsigned)

	puts $::wrDebug [mc {Adjusting compressing level...}]
	# INFO: -aoa�� overwrite all destination files�̴�
	# TODO: file nativename... �������� �������� �װ� �ڴ� �� �߰��� ��
	7za x -y -aoa -o$cApp(proj)\\temp $cApp(unsigned)

	# System compile�� ��� ������ �۾�
	if [regexp {compileRoutine} [info coroutine]] yield

	# �������� ��������. ������ �ǵ� �� ũ������ ������ �� �� �ִ�.
	if [file isdirectory $cApp(proj)/META-INF] {
		file copy -force -- $cApp(proj)/META-INF $cApp(proj)/temp/META-INF
	}
	file delete -- $cApp(unsigned)
	7za a -y -tzip -mx$::config(zlevel) $cApp(unsigned) $cApp(proj)\\temp\\*
	file delete -force -- $cApp(proj)\\temp
	
	if [regexp {compileRoutine} [info coroutine]] {
		puts $::wrInfo [mc {Successfully system compiled.}]
	} {
		puts $::wrInfo [mc {Successfully compiled.}]
	}
}

plugin {System compile} apkPath {
	coroutine compileRoutine ::Compile business $apkPath
	
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

plugin {Install framework} {args} {
	if {$args ne {}} {
		set frameworks $args
	} {
		set frameworks [dlgSelectAppFiles [mc {Select framework files}]]
	}

	if {$frameworks ne {}} {
		puts $::wrInfo [mc {Framework installing...}]
		foreach framework $frameworks {apktool if $framework}
		puts $::wrInfo [mc {Framework installed.}]
	}
}

plugin Sign apkPath {
	getNativePathArray $apkPath cApp

	if ![file exist $cApp(unsigned)] {
		puts $::wrError [mc {Unsigned file not found.}]
		if [file exist $cApp(signed)] {
			puts $::wrWarning [mc {It seems to be signed already.}]
		}
		return
	}
	
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
	if [file isdirectory $cApp(deoDir)] {
		catch {exec explorer $cApp(deoDir)}
	}
}

plugin {Optimize png} apkPath {
	getNativePathArray $apkPath cApp

	set pngFiles [lsearch -all -inline -not [scan_dir $cApp(proj) *.png] *$cApp(name)/build/*]
	set workers  [expr {int($::env(NUMBER_OF_PROCESSORS) * 1.4)}]
	
	# Make coroutine generator.
#	coroutine ::pngDeployer apply {{pngFiles mainRoutine} {
#		yield
#		foreach png $pngFiles {
#			puts deploy:$png
#			yield $png
#		}
#		$mainRoutine
#	}} $pngFiles [info coroutine]
	
	puts $::wrInfo [mc {Picture optimizing...}]
	
	foreach png $pngFiles {
		optipng $png
		update
	}
#	# Make and initiate coroutine workers.
#	for {set i 0} {$i < $workers} {incr i} {
#		puts "worker gen $i"
#		coroutine ::pngWorker($i) eval { while 1 {
#			set png [::pngDeployer]
#			if {$png eq {}} return
#
#			set pid [optipng $png]
#			set handle [::twapi::get_process_handle $pid -access generic_all]
#			set asyncBody [format {
#			} $handle [info coroutine]]
#			puts "asyncBody: $asyncBody"
#			::twapi::wait_on_handle $handle -executeonce 1 \
#				-async "::twapi::close_handle {$handle}; {[info coroutine]};#" 
#			yield
#		}}
#	}
	puts "worker generation finished"
#	yield
	puts "all finished"
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
			set proj [globFilter $cApp(proj) $cApp(deoDir)]
			set original [globFilter $cApp(path) $cApp(odex)]
			switch $detail {
				{Delete current result}				{set target [concat $result]}
				{Delete current workdir}			{set target [concat $proj]}
				{Delete current except original}	{set target [concat $result $proj]}
				{Delete current all}				{set target [concat $result $proj $original]}
			}
		}
	}

	if {$::cAppPaths ne {}} {
		set modDir [file dirname [lindex $::cAppPaths 0]]
	} {
		set modDir $::exeDir/modding
	}

	switch $detail {
		{Delete all result}				{set target [globFilter $modDir/signed_*.apk $modDir/unsigned_*.apk]}
		{Delete all workdir}			{set target [globFilter $::exeDir/projects/* $modDir/*.dex]}
		{Delete all except original}	{set target [globFilter $modDir/signed_*.apk $modDir/unsigned_*.apk $::exeDir/projects/* $modDir/*.dex]}
		{Delete all}					{set target [globFilter $modDir/*.apk $modDir/*.odex $::exeDir/projects/* $modDir/*.dex]}
	}

	set listItem {}
	if [llength $target] {
		foreach item $target {
			lappend listItem [AdaptPath $item]
			if [file isdirectory $item] {
				lappend listItem [mc (folder)]
			} {
				lappend listItem {}
			}
		}
		set confirm [ListAndConfirmDlg [join [list \
			[mc {Are you sure you want to delete these items?}] \
			[mc {Maybe these are sent to recycle bin.}]] \n] \
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
		after 1 [list {*}$delete $path]
		incr count
		update idletasks
	}
	
	puts $::wrInfo [mc {%d items are deleted.} $count]
}

plugin {Check update} {} {
#	if [::View::running_other_task?] return

	set ::currentOp {update}
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

proc queryApiLevel {apkPath} {
	# Query SDK version from original apk
	global manifest
	set api {}
	set err [catch {
	if [file exist $apkPath] {
		set w [::tcl::chan::variable manifest]
		bgopen -chan $w -conderror &&0 [getVFile aapt.exe] dump badging $apkPath
		close $w
		regexp {targetSdkVersion:'(\d*)'} $manifest] {} api
		if {$api eq {}} {
			regexp {sdkVersion:'(\d*)'} $manifest] {} api
		}
		unset manifest
	}}]
	if $err {
		puts $::wrVerbose [mc {API Level detection failed. Default value applied.}]
	}
	return $api
}

# smali�� odex������ ������θ� �ٲٴ� �Ķ���͸� �������� �ʱ� ������ ��¿ �� ����
# ������� ���빰 ���� ��θ� �� ���� ����ϰ� ���� ��ο� ��ġ��Ű�� �Ǿ���.
plugin {Deodex} {apkPath} {
	getNativePathArray $apkPath cApp
	
	ensureFiles $cApp(odex)
	
	puts -nonewline $::wrInfo [mc {Deodexing...}]
	
	set api [queryApiLevel $apkPath]
	if {$api ne {}} {set api "-a $api"}

	file delete -force $cApp(deoDir) $cApp(dex)
	set apkDir [file dirname $cApp(path)]
	baksmali -d $apkDir -d $apkDir/framework -x $cApp(odex) -o $cApp(deoDir) {*}$api
	puts $::wrInfo [mc { Complete.}]
}

plugin {Dex} {apkPath} {
	getNativePathArray $apkPath cApp
	
	set api [queryApiLevel $apkPath]
	if {$api ne {}} {set api "-a $api"}

	puts -nonewline $::wrInfo [mc {Dexing... }]
	catch {file mkdir [file dirname $cApp(dex)]}
	smali $cApp(deoDir) -o $cApp(dex)
	puts $::wrInfo [mc {Complete.}]
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

	foreach appIdx {signed unsigned path} {
		if [file exist $cApp($appIdx)] {
			7za e -y -aoa $cApp($appIdx) -o$cApp(dex) classes.dex
			break
		}
	}
	if [rdbleFile $cApp(dex)/classes.dex] {
		dex2jd $cApp(dex)/classes.dex
		return
	}
	
	if [rdbleFile $cApp(odex)] {
		::Deodex business $apkPath
		::Dex business $apkPath
		dex2jd $cApp(dex)
		return
	}
	
	puts $::wrError [mc {Cannot find classes.dex}]
}

proc bugReport {} {
	set null [tcl::chan::null]
	set reportFile [file nativename $::exeDir/ApkzBugReport.zip]
	file delete -force $reportFile
	set psr [auto_execok psr.exe]
	if {$psr ne {}} {
		bgopen -conderror &&0 $psr /output $reportFile /recordpid [pid]
	}
	append mes [mc {Textbox's verbose message appeared.}]\n
	if [file exist $reportFile] {
		bgopen -outchan $null [getVFile 7za.exe] e -y -o[getVFile] $reportFile
		file delete -force $reportFile
		set latestReport [lindex [lsort -decreasing [glob -directory [getVFile] *.mht]] 0]
		exec {*}[auto_execok start] {} $latestReport
		append mes [mc {Recorded report and textbox log will be sent intact.}]\n
	} {
		append mes [mc {Textbox log will be sent intact.}]\n
	}
	append mes [mc {Are you OK?}]

	set tCon .bottomConsole.tCmd
	$tCon tag config Verbose -elide 0
	set reply [modeless_dialog .reportConfirm [mc {Bug report}] $mes {} 0 [mc Yes] [mc No]]

	$tCon tag config Verbose -elide 1
	if $reply return

	set log [$tCon get 0.0 end]
	set logFile [open [getVFile log.txt] w]
	puts -nonewline $logFile $log
	close $logFile

	set reportFile [file rootname $reportFile].7z
	file delete -force $reportFile
	set includeMht [expr {[info exist latestReport] ? "-i!$latestReport" : {}}]
	bgopen -outchan $null [getVFile 7za.exe] a -y -mx9 $reportFile [getVFile log.txt] {*}$includeMht

	set archive [open $reportFile rb]
	set data [read $archive]
	close $archive
	set transErr [catch {http::geturl http://jeiea.dothome.co.kr/bugreport.php \
		-method POST -query $data -type {application/x-7z-compressed}}]
	if $transErr {
		puts $::wrError [mc {Cannot connect to server.}]
	} {
		puts $::wrInfo [mc {Report file has been sent.}]
	}
	close $null
}
