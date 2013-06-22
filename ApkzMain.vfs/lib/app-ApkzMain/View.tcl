namespace eval View {
	namespace export TraverseCApp
	variable currentOp ""
	variable cappLabel ""
	variable tCon

	namespace import ::tooltip::tooltip
}

package require Tk
package require Ttk
package require BWidget

proc View::init args {
	# Create vertical paned view
	pack [ttk::label .lApp -textvariable ::View::cappLabel] -fill x -side top
	pack [ttk::panedwindow .p -orient vertical] \
		-padx 3 -pady 3 -expand 1 -fill both -side bottom
	.p add [ttk::frame .p.f1 -relief solid]
	.p add [ttk::labelframe .p.f2 -width 100 -height 100]

	bottomPane.generate .p.f2
	# 초보자 모드
	if 1 {
		simpleView.generate .p.f1
		simpleView.pack .p.f1
		#	[winfo parent $pane] sashpos 0 300
	} {
		detailView.generate .p.f1
	}
	menu.attach

	wm title . [mc {ApkZipper %s %s} $::apkzver $::apkzDistver]
	bind . <Escape> {destroy .}
	tooltip delay 50

	#bind all <Key-Control_L> {puts "a\n"}
	#bind all <KeyRelease-Control_L> {puts "b\n"}
	#bind all <KeyPress> {puts "%%K=%K, %%A=%A, %%k=%k\n"}

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
	wm geometry . 640x480
}

proc View::bottomPane.generate {pane} {
	#textcon.generate
	set underframe [ttk::frame $pane.fLog]
	pack $underframe -side top -expand 1 -fill both
	pack [text $underframe.tCmd -yscrollcommand "$underframe.sb set " \
		-wrap char -width 1 -height 1] -side left -fill both -expand 1
	pack [ttk::scrollbar $underframe.sb -orient vertical \
		-command "$underframe.tCmd yview "] -side right -fill both

	variable tCon $underframe.tCmd

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

	$tCon tag config Error -foreground red
	$tCon tag config Warning -foreground #ee4400
	$tCon tag config Verbose -elide 1
	$tCon tag config Debug -foreground #000040

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
	bind $tCon <KeyPress> {
		# Control_L 같은 Modifier는 일단 통과
		if {[string first _ "%K"] != -1} return
		# 방향키도 범위선택에 중요하므로 통과
		if [regexp {Up|Down|Left|Right} "%K"] return
			focus .p.f2.ePrompt
		
		event generate .p.f2.ePrompt <KeyPress> -keycode %k
	}

	pack [ttk::entry $pane.ePrompt] -fill x -side bottom
	bind . <FocusIn> {
		if {[string first "%W" ".p.f2.fLog.tCmd"] == -1} {
			namespace code {focus .p.f2.ePrompt}
		}
	}

	bind $pane.ePrompt <Return> {
		set cmd [.p.f2.ePrompt get]
		if {$cmd != ""} {
			.p.f2.ePrompt delete 0 end
			::Session::CommandParser $cmd
		}
	}
	focus $pane.ePrompt
}

proc View::simpleView.generate {pane} {
#	set sw [ScrolledWindow $pane.sw -scrollbar horizontal]
#	pack $sw -fill both -expand true
#	set sf [ScrollableFrame $sw.sf]
#	$sw setwidget $sf
#	 이제 이 uf에다가 집어넣으면 scrollable의 내용을 채울 수 있다.
#	set uf [$sf getframe]

#	addScrollBindings $sw.sf $pane

	foreach {name label} {
		bSelLocal	{Select app}
		bImport		{Import from phone}
		bManual		{Change to manual mode}
		bExtract	{Extract}
		bDecompile	{Decompile}
		bIFramework {Install framework}
		bExplProj	{Explore app dir}
		bExplOdex	{Explore dex dir}
		bPacking	{Pack}
		bSigning	{Sign}
		bInstall	{Install}
		bExport		{Export to phone}
	} {
		ttk::button $pane.$name -text [mc $label] -command \
			[list $label business]\;[list ::View::simpleView.pack $pane]
		puts $pane.$name
	}
}

proc View::simpleView.pack {pane} {
	pack forget {*}[winfo children $pane]
	set parent [winfo parent $pane]
	$parent pane [lindex [$parent panes] 0] -weight 1
	$parent pane [lindex [$parent panes] 1] -weight 1

	proc simplePack {widget} [format {
		pack %s.$widget -side left -expand true -fill both
	} $pane]

	if {$::cAppPaths eq {}} {
		simplePack bSelLocal
		simplePack bImport
		simplePack bManual
	}
	getNativePathArray [lindex $::cAppPaths 0] cApp
	if [file exist $cApp(path)] {
		simplePack bExtract
		simplePack bDecompile
		simplePack bDeodex
	}
	if [file isdirectory $cApp(proj)] {
		simplePack bExplProj
		simplePack bPacking
	}
	if [file isdirectory [file rootname $cApp(proj)].dex] {
		simplePack bExplOdex
		simplePack bPacking
	}
	if [file exist $cApp(unsigned)] {
		simplePack bInstall
		simplePack bSign
		simplePack bExport
	}
	textcon.verbose Info
}

# 버튼 생성
proc View::detailView.pack {pane} {
	set parent [winfo parent $pane]
	$parent pane [lindex [$parent panes] 0] -weight 0
	$parent pane [lindex [$parent panes] 1] -weight 0

	set count 0
	foreach {column proc proc2} $::config(btns) {
		# 생성과 바인딩
		incr colStack($column)
#		set path $parentWin.b$colStack($column)
#		pack [ttk::button $path -text "$count. [mc $proc]" \
#			-command "coroutine Trav\[generateID\] ::Session::TraverseCApp {::$proc}"] -padx 3 -expand true -fill both
		pack 

		# 두번째 바인딩
		if {$proc2 != ""} {
			bind $path $::config(mod2) "coroutine Trav\[generateID\] ::Session::TraverseCApp {::$proc2}"
			# TODO: 이 Right click을 mod2로 바꿔야겠지?
			tooltip $path [mc {Right click: %s} [mc $proc2]]
		}
		incr count
	}
	unset colStack parentWin path count

	foreach fram [winfo children $pane] {
		grid rowconfigure $fram [seq [llength [winfo children $fram]]] -weight 1
	}
}

proc View::detailView.generate {pane} {
	foreach {column proc proc2} $::config(btns) {
		# 부모 프레임 등록
		set parentWin $pane.c$column
		if ![winfo exists $parentWin] {
			ttk::frame $parentWin
		}

		# 생성과 바인딩
		incr colStack($column)
		set path $parentWin.b$colStack($column)
		ttk::button $path -text "$count. [mc $proc]" \
			-command "coroutine Trav\[generateID\] ::Session::TraverseCApp {::$proc}"]

		# 두번째 바인딩
		if {$proc2 != ""} {
			bind $path $::config(mod2) "coroutine Trav\[generateID\] ::Session::TraverseCApp {::$proc2}"
			# TODO: 이 Right click을 mod2로 바꿔야겠지?
			tooltip $path [mc {Right click: %s} [mc $proc2]]
		}
		incr count
	}
}

proc View::textcon.verbose {level} {
	set levels {Error Warning Info Debug Verbose}

	if {$level ni $levels} {
		error {verbose level incorrect} "$level is not supported level." {custom verbose}
	}

	variable tCon
	set overlevel false
	foreach tag $levels {
		if {$level eq $tag} {
			set overlevel true
		}
		$tCon tag config $tag -elide [expr ($overlevel) ? true : false]
	}
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
		set markRemoved [string map {& {}} [mc $label]]
		[winfo parent $menu] add cascade -label $markRemoved \
			-menu $menu -underline [string first & [mc $label]]
	}
	# view change menu
#	set markRemoved [string map {& {}} [mc $label]]
#	.mbar add command -label [mc {}] 

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

	$mSdk add command -label [mc {ADB Shell}] -command {
			# Eclipse 환경에서 개발할 때는 Eclipse 콘솔로 출력이 나갈 수 있으니 유의하자
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
}

oo::class create InterChan {
	constructor {body} {
		oo::objdefine [self] method write {chan data} $body
	}
	method initialize {ch mode} {
		return {initialize finalize watch write}
	}
	method finalize {ch} {
		my destroy
	}
	method watch {ch events} {
		# Must be present but we ignore it because we do not
		# post any events
	}
}

oo::class create CapturingChan {
	variable var
	constructor {varnameOrArgs {body ""}} {
		# Make an alias from the instance variable to the global variable
		if {[llength $varnameOrArgs] == 2} {
			oo::objdefine [self] method write $varnameOrArgs $body
		} {
			my eval [list upvar \#0 $varnameOrArgs var]
		}
	}
	method initialize {handle mode} {
		if {$mode ne "write"} {error "can't handle reading"}
		return {finalize initialize write}
	}
	method finalize {handle} {
		# Do nothing, but mandatory that it exists
	}
	method write {handle bytes} {
		append var $bytes
		# Return the empty string, as we are swallowing the bytes
		return {}
	}
}

#set myBuffer ""
#chan push stdout [CapturingChan new myBuffer]

#chan pop stdout
