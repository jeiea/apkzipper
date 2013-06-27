package require Tk
package require Ttk
package require BWidget
package require tkdnd

namespace eval View {
	namespace export TraverseCApp
	variable currentOp ""
	variable cappLabel ""
	variable tCon

	namespace import ::tooltip::tooltip
}

proc View::init args {
	# Create vertical paned view
	set stat .stat
	pack [StatusBar $stat -showresize 0] -fill x
	$stat add [ttk::label $stat.lApp -textvariable ::View::cappLabel]
#	$stat add [ttk::progressbar $stat.prog -mode indeterminate]
#	$stat.prog start 10

	pack [ttk::panedwindow .p -orient vertical] \
		-padx 3 -pady 3 -expand 1 -fill both -side bottom

	menu.attach
	switchView $::config(viewMode)

	wm title . [mc {ApkZipper %s %s} $::apkzver $::apkzDistver]
	bind . <Escape> {destroy .}
	tooltip delay 50

	# Drag and Drop 바인딩 부분
	tkdnd::drop_target register . DND_Files

	bind . <<Drop:DND_Files>> {
		set dropPaths %D
		set forceBreak false
		set reply {}

		{::Session::Select app} $dropPaths

		return %A
	}

	wm minsize . 450 200
}

proc View::bottomPane.generate {} {
	set frame .bottomConsole
	if [winfo exists $frame] {
		return $frame
	}
	
	ttk::frame $frame
#	set underframe [ttk::frame $pane.fLog]
	pack [set prompt [ttk::combobox $frame.cbPrompt]] -fill x -side bottom
	bind . <FocusIn> [format {
		if {[string first "%%W" "%1$s.tCmd"] == -1} {
			namespace code {focus %1$s}
		}
	} $prompt]

	bind $prompt <Return> [format {
		set cmd [%1$s get]
		if ![string is space $cmd] {
			addHist commandLine $cmd
			%1$s delete 0 end
			::Session::CommandParser $cmd
		}
	} $prompt]
	$prompt config -postcommand [format {%s config -values $::hist(commandLine)} $prompt]
	tooltip $prompt [join [list \
		[mc {Supported command:}]\
		[mc {shell, connect, exit}]\
		[mc {push [<remote path>]}]\
		[mc {push <local> <remote>}]\
		[mc {pull <remote path>}]\
		[mc {pull <remote> <local>}]\
		[mc {Numbers written in detail view are accepted.}]\
	] \n]
	focus $prompt
	
	pack [text $frame.tCmd -yscrollcommand "$frame.sb set " \
		-wrap char -width 1 -height 1] -side left -fill both -expand 1
	pack [ttk::scrollbar $frame.sb -orient vertical \
		-command "$frame.tCmd yview "] -side right -fill both

	variable tCon $frame.tCmd

	foreach ideal {"나눔고딕코딩" "맑은 고딕" "Consolas" "돋움체"} {
		if {[lsearch -exact [font families] $ideal] != -1} {
			$tCon config -font [list $ideal 9]
			break
		}
	}

	foreach level {Verbose Debug Info Warning Error} {
		global rd$level wr$level
		lassign [chan pipe] rdLevel wrLevel
		lassign [list $rdLevel $wrLevel] ::rd$level ::wr$level
		chan configure $rdLevel -blocking false -buffering none
		chan configure $wrLevel -blocking false -buffering none
		chan event $rdLevel readable [namespace code [list tkPuts $rdLevel $level]]
	}

	proc ::bgerror msg {
		puts $::wrError $msg
		puts $::wrVerbose "$::errorCode: $::errorInfo"
	}

	$tCon tag config Error -foreground red
	$tCon tag config Warning -foreground orangered
	$tCon tag config Debug -foreground navy
	$tCon tag config Verbose -foreground purple -elide 1

	namespace inscope :: [list rename $tCon _$tCon]

	proc ::$tCon args [format {
		switch -exact -- [lindex $args 0] {
			insert {}
			delete {}
			default {
				return [eval {%s} $args]
			}
		}
	} _$tCon]

	proc tkPuts {rdLevel tag} [format {
		set tCon {%s}
		set data [read $rdLevel]

		if {[lindex [$tCon yview] 1] == 1} {
			set autoscroll true
		} {
			set autoscroll false
		}
		$tCon insert end $data $tag
		if $autoscroll {
			$tCon yview end
		}
	} _$tCon]

	# event의 mapping keys to virtual event를 자세히 읽어야 하는구나 ㅡㅡ;
	# 대충 이런 Custom event가 우선순위가 높고, 별 처리를 안 해주면 다른 이벤트는 처리 안 하는 듯 하다.
	# 아님 break해도 의미가 있고.
	# 근데 return 이거 빼면 윈키 누를 때 에러뜬다. 이유가 뭐였더라..
	bind $tCon <<Copy>> return
	bind $tCon <<SelectAll>> return
	bind $tCon <KeyPress> [format {
		# Control_L 같은 Modifier는 일단 통과
		if {[string first _ "%%K"] != -1} return
		# 방향키도 범위선택에 중요하므로 통과, PgUp, PgDn통과
		if [regexp {Up|Down|Left|Right|Prior|Next} "%%K"] return
			focus %1$s
		
		event generate %1$s <KeyPress> -keycode %%k
	} $prompt]

	#bind all <Key-Control_L> {puts "a\n"}
	#bind all <KeyRelease-Control_L> {puts "b\n"}
#	bind all <KeyPress> {puts "%%K=%K, %%A=%A, %%k=%k\n"}

	return $frame
}

plugin {Change to manual mode} {} {
	.mbar invoke 4
	rename [info coroutine] {}
	yield
}

plugin {Pack} {apkPath} {
	getNativePathArray $apkPath cApp
	
	if [file exist $cApp(proj)/apktool.yml] {
		set fYml [open $cApp(proj)/apktool.yml]
		set apkInfo [read $fYml]
		close $fYml
		if [regexp {com\.android} $apkInfo] {
			set plugin {::System compile}
		} {
			set plugin {::Compile}
		}
	} {
		set plugin {::Zip}
	}
	coroutine pack[generateID] $plugin business $apkPath
}

proc View::simpleView {} {
	set paneWindow .p
	foreach pane [$paneWindow panes] {
		$paneWindow forget $pane
	}
	$paneWindow add [simpleView.generate] -weight 1
	$paneWindow add [bottomPane.generate] -weight 1
	textcon.verbose Info
	set ::config(viewMode) simpleView
}

proc View::simpleView.generate {} {
	destroy .sw
	set sw [ScrolledWindow .sw -scrollbar horizontal]
	set sf [ScrollableFrame $sw.sf -constrainedheight 1]
	$sw setwidget $sf
	set frame [$sf getframe]

	# pre-construct button
	foreach {name label} {
		bSelLocal	{Select app}
		bImport		{Import from phone}
		bManual		{Change to manual mode}
		bExtract	{Extract}
		bDecompile	{Decompile}
		bDeodex		{Deodex}
		bIFramework {Install framework}
		bExplProj	{Explore app dir}
		bExplOdex	{Explore dex dir}
		bPacking	{Pack}
		bSigning	{Sign}
		bInstall	{Install}
		bExport		{Export to phone}
	} {
		ttk::button $frame.$name -width 10 -text [mc $label] -command \
			"coroutine Trav\[generateID\] eval {::Session::TraverseCApp {::$label};::View::simpleView}"
	}

	lappend listPack bSelLocal bImport bManual
	
	if {$::cAppPaths ne {}} {
		getNativePathArray [lindex $::cAppPaths 0] cApp
		if [file exist $cApp(path)] {
			lappend listPack bExtract bDecompile bDeodex
		}
		if [file isdirectory $cApp(proj)] {
			lappend listPack bExplProj bPacking
		}
		if [file isdirectory [file rootname $cApp(proj)].odex] {
			lappend listPack bExplOdex bPacking
		}
		if [file exist $cApp(unsigned)]||[file exist $cApp(signed)] {
			lappend listPack bSigning bInstall bExport
		}
		set duplicate [lsearch -all -exact $listPack bPacking]
		foreach other [lrange $duplicate 0 end-1] {
			set listPack [lreplace $listPack $other $other]
		}
	}
	
	bind $sf <Configure> {
		set numButton [llength [pack slaves [%W getframe]]]
		%W configure -areawidth [expr {$numButton * [winfo width %W] / 3}]
	}
	foreach widget $listPack {
		pack $frame.$widget -side left -fill both -expand true
	}

	foreach widget [allwin $frame] {
		bindtags $widget [concat [bindtags $widget] SCROLLAREA]
	}
	bind SCROLLAREA <MouseWheel> [format {
		lassign [%1$s xview] left right
		set width [expr {$right - $left}]
		%1$s xview moveto [expr {$left - (%%D / 120 * $width / 3)}]
	} $sf]
	bind SCROLLAREA <4> "$sf xview scroll -5 units"
	bind SCROLLAREA <5> "$sf xview scroll +5 units"
	# 왜 딜레이를 줘야 해결되는지 의문. 다른 컴퓨터에서 동작 안할 수 있음.
	after 200 "$sf xview moveto 1"
	return $sw
}

proc View::detailView {} {
	set paneWindow .p
	foreach pane [$paneWindow panes] {
		$paneWindow forget $pane
	}
	$paneWindow add [detailView.generate] -weight 0
	$paneWindow add [bottomPane.generate] -weight 0
	textcon.verbose Debug
	set ::config(viewMode) detailView
}

# 버튼 생성
proc View::detailView.generate {} {
	set frame .detailView
	if [winfo exists $frame] {
		return $frame
	}
	
	ttk::frame $frame
	set count 0
	foreach {column proc proc2} $::config(btns) {
		# 부모 프레임 등록
		set parentWin $frame.c$column
		if ![winfo exists $parentWin] {
			pack [ttk::frame $parentWin] -side left -expand true -fill both
		}

		# 생성과 바인딩
		incr colStack($column)
		set path $parentWin.b$colStack($column)
		pack [ttk::button $path -text "$count. [mc $proc]" \
			-command "coroutine Trav\[generateID\] ::Session::TraverseCApp {::$proc}"] -padx 3 -expand true -fill both

		# 두번째 바인딩
		if {$proc2 != ""} {
			bind $path $::config(mod2) "coroutine Trav\[generateID\] ::Session::TraverseCApp {::$proc2}"
			# tooltip이 msgcat을 자동으로 해 주는 걸 뭐라는 건 아닌데, 이왕 해 줄거면
			# mc additional arg까지 다 받아주면 좀 좋나?
			tooltip $path [mc {Right click: %s} [mc $proc2]]
		}
		incr count
	}

	foreach col [winfo children $frame] {
		grid rowconfigure $col [seq [llength [winfo children $col]]] -weight 1
	}
	
	return $frame
}

proc View::textcon.verbose {level} {
	set levels {Error Warning Info Debug Verbose}

	if {$level ni $levels} {
		error {verbose level incorrect} "$level is not supported level." {custom verbose}
	}

	variable tCon
	set overlevel false
	foreach tag $levels {
		$tCon tag config $tag -elide [expr ($overlevel) ? true : false]
		if {$level eq $tag} {
			set overlevel true
		}
	}
}

proc View::tutorialView {} {
	set paneWindow .p
	foreach pane [$paneWindow panes] {
		$paneWindow forget $pane
	}
	$paneWindow add [tutorialView.generate] -weight 3
	$paneWindow add [bottomPane.generate] -weight 7
	textcon.verbose Debug
	set ::config(viewMode) tutorialView
}

proc View::tutorialView.generate {} {
	set frame .tutorialView
	
	if [winfo exists $frame] {
		return $frame
	}
	ttk::frame $frame -width 200 -height 25
	
	foreach {name label} {
		app {Import}
		job {Modify and pack}
		pack {Export}
	} {
		ttk::labelframe $frame.$name -text [mc $label]
	}
	set fDeo [ttk::frame $frame.fDeodex]
	
	foreach {name label description} {
		bSelLocal	{Select app}		"Select .apk, .jar file from a local disk."
		bImport		{Import from phone}	"Import file from connected device."
		bExtract	{Extract}			"Extract selected files' contents.\nIt's enough to modify .png images."
		bDecompile	{Decompile}			"Unpack selected files' contents with decoding some source code to smali.\nRight click is 'Install framework' which registers\nrequired files for compile/decompile."
		bDeodex		{Deodex}			"Decode the .odex file.\nIt should be on same location."
		bOptipng	{Optimize png}		"Reduce .png files' size.\nThere's not quality decrease."
		bIFramework {Install framework} "Register files required to compile/decompile."
		bExplProj	{Explore project}	"Open extracted contents' directory"
		bExplOdex	{Explore dex dir}	"Open .odex contents' directory"
		bDex		{Dex}				"Pack deodexed contents.\nIf you do it before zip/compile, changes will be applied."
		bZip		{Zip}				"Pack 'Extracted' contents.\nDon't use it with 'Decompile'"
		bCompile	{Compile}			"Pack decompiled contents.\nDon't use it with 'Extract'\nRight click is 'System compile' which preserve resource.arsc"
		bSigning	{Sign}				"Sign packed .apk/.jar file.\nOriginal sign will be remained after packing."
		bZipalign	{Zipalign}			"Refine packed .apk/jar file.\nIf you sign after zipalign, alignment may be ruined."
		bInstall	{Install}			"Install .apk file to a device.\nSystem app maybe cannot."
		bExport		{Export to phone}	"Send file to a device."
	} {
		ttk::button $frame.$name -width 10 -text [mc $label] -command \
			"coroutine Trav\[generateID\] ::Session::TraverseCApp {::$label}"
		tooltip $frame.$name [mc $description]
	}
	bind $frame.bCompile <ButtonRelease-3> {
		coroutine Trav[generateID] ::Session::TraverseCApp {::System compile}
	}
	bind $frame.bDecompile <ButtonRelease-3> {
		coroutine Trav[generateID] ::Session::TraverseCApp {::Install framework}
	}
	
	set fApp $frame.app
	pack $frame.bSelLocal -expand true -fill both -in $fApp
	pack $frame.bImport -expand true -fill both -in $fApp
	place $fApp -relx 0 -relwidth 0.2 -relheight 1
	
	set fPack $frame.pack
	foreach win {bSigning bZipalign bInstall bExport} {
		pack $frame.$win -expand true -fill both -in $fPack
	}
	place $fPack -relx 0.8 -relwidth 0.2 -relheight 1
	
	set fJob $frame.job
	foreach {row col win} {
		0 0 bExtract
		1 0 bDecompile
		0 1 bExplProj
		1 1 bOptipng
		0 2 bZip
		1 2 bCompile
	} {
		grid $frame.$win -row $row -column $col -sticky news -in $fJob
		grid columnconfigure $fJob $col -weight 1
		grid rowconfigure $fJob $row -weight 1
	}
	place $fJob -relx 0.2 -relwidth 0.6 -relheight 0.7
	
	pack $frame.bDeodex -side left -fill both -expand true -in $fDeo
	pack $frame.bExplOdex -side left -fill both -expand true -in $fDeo
	pack $frame.bDex -side left -fill both -expand true -in $fDeo
	place $fDeo -relx 0.2 -rely 0.75 -relwidth 0.6 -relheight 0.25
	return $frame
}

# 다음에 바뀔 뷰를 리턴함
proc View::switchView {args} {
	set chain {simpleView detailView tutorialView simpleView detailView}
	if [llength $args] {
		set idx [lsearch -exact $chain [lindex $args 0]]
	} {
		set idx [expr [lsearch -exact $chain $::config(viewMode)]+1]
	}
	{*}[lindex $chain $idx]
	return [lindex $chain $idx+1]
	#	[winfo parent $pane] sashpos 0 300
}

proc View::menuUnderline {label} {
	set markRemoved  [string map {& {}} $label]
	set underlineIdx [string first & $label]
	return [list -label $markRemoved -underline $underlineIdx]
}

proc View::menu.attach {} {
	catch {destroy .mbar}
	. config -menu [menu .mbar]

	foreach {label menu} [list \
		{&Config}		[set mConfig	[menu .mbar.config]			] \
		{&SDK Function}	[set mSdk		[menu .mbar.sdk]			] \
		{&Etc Function}	[set mEtc		[menu .mbar.etc -tearoff 0]	] \
		{Zip level}						[menu $mConfig.zlevel -tearoff 0] \
		{Decompile target}				[menu $mConfig.target -tearoff 0] \
	] {
		[winfo parent $menu] add cascade {*}[menuUnderline [mc $label]] -menu $menu
	}
	# view change menu
	set label [expr {$::config(viewMode) eq {simpleView} ? {detailView} : {simpleView}}]
	.mbar add command {*}[menuUnderline [mc $label]] \
		-command {.mbar entryconf 4 {*}[::View::menuUnderline [mc [::View::switchView]]]}


	foreach idx [seq 10] {$mConfig.zlevel add radiobutton \
			-label [mc "Ziplevel $idx"] -value $idx -variable ::config(zlevel)}
	foreach {label opt} [list	\
		{Sources}		{-r   } \
		{Resources}		{-s   } \
		{Both}			{     } \
		{The others}	{-r -s} \
	] {
		$mConfig.target add radiobutton -label [mc $label] \
			-variable ::config(decomTargetOpt) -value $opt
	}
	$mConfig add command {*}[menuUnderline [mc {&Reset config}]] -command {
		array unset ::config
		array set ::config [array get ::configDefault]
		array unset ::hist
		array set ::hist [array get ::histDefault]
		{::Select app} business {}
		puts $::wrInfo [mc {Configuration is set to default.}]
	}
	
	$mSdk add command -label [mc {ADB Shell}] -command {
		# 일부러 title case한 이유는 콘솔 창 이름으로 쓰이기 때문
		::WinADB::adb_waitfor Shell
	}
	$mSdk add checkbutton -label [mc {Take phone log}] -variable bLogcat \
		-onvalue 1 -offvalue 0 -command {{::WinADB::ADB logcat} $bLogcat}
	foreach {label cmd} {
		{ADB Connect}		{coroutine ADBcon[generateID] {::WinADB::ADB connect}}
		{Reboot}			{::WinADB::adb_waitfor reboot}
		{Enter recovery}	{::WinADB::adb_waitfor {reboot recovery}}
		{Enter download}	{::WinADB::adb_waitfor reboot-bootloader}
	} {
		$mSdk add command -label [mc $label] -command $cmd
	}
	# reboot bootloader로 공백을 써도 되긴 한데 호환성을 위해서 -를 붙였다. 이전버전 adb를 쓰는 사람도 있을테니.
	# TODO: FASTBOOT
	# .mbar.sdk add command -label [mc FLASH_RECOVERY] -command {}

	foreach {label cmd} [list \
		{Check update}	{{::Check update} business} \
		{Visit website}	{eval exec [auto_execok start] {} http://ddwroom.tistory.com/ &} \
		Help {tk_messageBox -title [mc Sorry] -detail [mc {Not yet ready}]}] \
	{
		$mEtc add command -label [mc $label] -command $cmd
	}
	$mEtc add cascade -label [mc {Clean folder}] -menu [menu $mEtc.clean -tearoff 0]

	foreach item {
		{Delete current result}
		{Delete current workdir}
		{Delete current except original}
		{Delete current all}
		{Delete all result}
		{Delete all workdir}
		{Delete all except original}
		{Delete all}
	} {
		$mEtc.clean add command -label [mc $item] -command \
			"coroutine CleanOp\[generateID\] {::Clean folder} [list $item]"
	}
	
	$mEtc add command -label [mc {Bug report}] -command ::bugReport
}
