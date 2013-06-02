source $libpath/ApkzSub.tcl

namespace eval GUI {
	namespace export TraverseCApp Print
	variable currentOp ""
	variable cappLabel ""

	namespace import ::tooltip::*

	proc init args {
		menu.generate
		widget.layout
	}

	proc widget.generate {} {

	}

	proc widget.layout {} {

	}

	wm title . [mc "ApkZipper %s %s" $::apkzver $::apkzDistver]
	bind . <Escape> {destroy .}
	tooltip delay 50

	proc menu.generate {} {
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
			::ModApk::Adb version
			# Eclipse ȯ�濡�� ������ ���� Eclipse �ַܼ� ����� ���� �� ������ ��������
			::ModApk::Adb_waitfor Shell
		}
		$mSdk add checkbutton -label [mc {Take phone log}] -variable bLogcat \
			-onvalue 1 -offvalue 0 -command {{::ModApk::ADB logcat} $bLogcat}
		foreach {label cmd} [list \
			{ADB Connect}		{{::ModApk::ADB connect}}					\
			{Reboot}			{::ModApk::Adb_waitfor reboot}				\
			{Enter recovery}	{::ModApk::Adb_waitfor {reboot recovery}}	\
			{Enter download}	{::ModApk::Adb_waitfor reboot-bootloader}	\
		] {
			$mSdk add command -label [mc $label] -command $cmd
		}
		# reboot bootloader�� ������ �ᵵ �Ǳ� �ѵ� ȣȯ���� ���ؼ� -�� �ٿ���. �������� adb�� ���� ����� �����״�.
		# TODO: FASTBOOT
		# .mbar.sdk add command -label [mc FLASH_RECOVERY] -command {}

		foreach {label cmd} [list \
			{Check update}	{{::ModApk::Check update}} \
			{Visit website}	{exec cmd /C start "" http://ddwroom.tistory.com/ &} \
			Help {tk_messageBox -title [mc Sorry] -detail [mc {Not yet ready}]}] {
			$mEtc add command -label [mc $label] -command $cmd
		}
		$mEtc add cascade -label [mc {Clean folder}] -menu [menu $mEtc.clean -tearoff 0]

		foreach item {
		{Delete current result} {Delete current workdir} {Delete current except original} {Delete current all} \
		{Delete all result} {Delete all workdir} {Delete all except original} {Delete all}} {
			$mEtc.clean add command -label [mc $item] -command "{::ModApk::Clean folder} [list $item]"
		}
	}

	# ��ư ���� ����
	pack [ttk::label .lApp -textvariable ::GUI::cappLabel] -fill x -side top
	pack [ttk::panedwindow .p -orient vertical] -padx 3 -pady 3 -expand 1 -fill both -side bottom
	.p add [ttk::frame .p.f1 -relief solid]
	.p add [ttk::labelframe .p.f2 -width 100 -height 100]

	set count 0
	foreach {column proc proc2} $::config(btns) {
		# �θ� ������ ���
		set parentWin .p.f1.c$column
		if ![winfo exists $parentWin] {
			pack [ttk::frame $parentWin] -side left -expand true -fill both
		}

		# ������ ���ε�
		incr colStack($column)
		set path $parentWin.b$colStack($column)
		pack [ttk::button $path -text "$count. [mc $proc]"] -padx 3 -expand true -fill both

		if {$proc != ""} {
			bind $path $::config(mod1) "::GUI::TraverseCApp {::ModApk::$proc}"
		}

		# �ι�° ���ε�
		if {$proc2 != ""} {
			bind $path $::config(mod2) "::GUI::TraverseCApp {::ModApk::$proc2}"
			# TODO: �� Right click�� mod2�� �ٲ�߰���?
			tooltip $path [mc {Right click: %s} [mc $proc2]]
		}
		incr count
	}
	unset colStack parentWin path count

	# ��ư ���� ��

	# �ؽ�Ʈ�ڽ� ����
	set under [ttk::frame .p.f2.fLog]
	pack $under -side top -expand 1 -fill both
	pack [text $under.tCmd -width 0 -height 0 -yscrollcommand "$under.sb set " -wrap char] -side left -fill both -expand 1
	pack [ttk::scrollbar $under.sb -orient vertical -command "$under.tCmd yview "] -side right -fill both
	
	foreach ideal {"��������ڵ�" "���� ���" "Consolas" "����ü"} {
		if {[lsearch [font families] $ideal] != -1} {
			$under.tCmd config -font [list $ideal 9]
			break
		}
	}
	namespace inscope :: "rename $under.tCmd _$under.tCmd"

	proc ::$under.tCmd args {
		switch -exact -- [lindex $args 0] {
			insert {}
			delete {}
			default {
				return [eval _.p.f2.fLog.tCmd $args]
			}
		}
	}

	unset under

	proc Print data {
		set wLogText _.p.f2.fLog.tCmd
		$wLogText insert end $data
		$wLogText yview end
	}

	pack [ttk::entry .p.f2.ePrompt] -fill x -side bottom
	bind . <FocusIn> {
		if {[string first "%W" ".p.f2.fLog.tCmd"] == -1} {
			namespace code {focus .p.f2.ePrompt}
		}
	}

	# event�� mapping keys to virtual event�� �ڼ��� �о�� �ϴ±��� �Ѥ�;
	# ���� �̷� Custom event�� �켱������ ����, �� ó���� �� ���ָ� �ٸ� �̺�Ʈ�� ó�� �� �ϴ� �� �ϴ�.
	# �ƴ� break�ص� �ǹ̰� �ְ�.
	# �ٵ� return �̰� ���� ��Ű ���� �� �������. ������ ��������..
	bind .p.f2.fLog.tCmd <<Copy>> return
	bind .p.f2.fLog.tCmd <<SelectAll>> return
	bind .p.f2.fLog.tCmd <KeyPress> {
		# Control_L ���� Modifier�� �ϴ� ���
		if {[string first _ "%K"] != -1} return
		# ����Ű�� �������ÿ� �߿��ϹǷ� ���
		if [regexp {Up|Down|Left|Right} "%K"] return

		focus .p.f2.ePrompt
		event generate .p.f2.ePrompt <KeyPress> -keycode %k
	}

	bind .p.f2.ePrompt <Return> {
		set cmd [.p.f2.ePrompt get]
		if {$cmd != ""} {
			.p.f2.ePrompt delete 0 end
			::GUI::CommandParser $cmd
		}
	}
	focus .p.f2.ePrompt
	#�ؽ�Ʈ�ڽ� ���� ��

	foreach fram [winfo children .p.f1] {
		grid rowconfigure $fram [seq [llength [winfo children $fram]]] -weight 1
	}

	#bind all <Key-Control_L> {Print "a\n"}
	#bind all <KeyRelease-Control_L> {Print "b\n"}
	#bind all <KeyPress> {::GUI::Print "%%K=%K, %%A=%A, %%k=%k\n"}

	wm minsize . 450 200
	wm geometry . 640x480

	# Drag and Drop ���ε� �κ�
	tkdnd::drop_target register . DND_Files

	bind . <<Drop:DND_Files>> {
		set dropPaths %D
		set forceBreak false
		set reply {}

		{::ModApk::Select app} $dropPaths

		return %A
	}

	proc CommandParser command {
		set cmd [lindex $command 0]
		# HACK: ���߿� VFSó�� ������... �̰͵� ������ �� �� ����ϰ�
		if {$cmd == 0} {
			Print "adb [lrange $command 1 end]"
			{::ModApk::Adb pull} {*}[lrange $command 1 end]
			return
		}
		if [string is digit $cmd] {
			TraverseCApp "::ModApk::[lindex $::config(btns) [expr $cmd * 3 + 1]]"
		}
	}

	proc running_other_task? {} {
		variable currentOp

		if {$currentOp != ""} {
			if ![winfo exist .mlsWait] {
				toplevel .mlsWait
				wm title .mlsWait [mc {Please wait}]
				pack [ttk::label .mlsWait.msg -text [mc {Please wait}]\n[mc {Already op exist}]] -expand 1 -fill both
			}
			raise .mlsWait
			after 3000 {destroy .mlsWait}
			return true
		} {
			return false
		}
	}

	proc TraverseCApp methodName {
		global cAppPaths
		variable currentOp

		if [running_other_task?] return

		if ![string match "apkPath*" [info args $methodName]] {
			$methodName
			return
		}

		set currentOp $methodName
		try {
			if [info exist cAppPaths] {
				foreach apkPath $cAppPaths {
					if [catch {$methodName $apkPath} errmsg errinfo] {
						if {[dict exist $errinfo -errorcode] && 
							[dict get $errinfo -errorcode] == 100} {
							Print "[mc ERROR]: $errmsg\n"
						} {
							# �̷������� ¥�� �� ����ȭ���Ѿ�...
							if {[string first charset.MalformedInputException $errmsg] != -1} {
								Print "[mc ERROR]: [mc "File name malformed.\nPlease retry after rename. (e.g. test.apk)"]\n"
							} {
								Print "[mc ERROR]: [dict get $errinfo -errorinfo]\n"
							}
						}
					}
				}
			}
		} finally {set currentOp ""}
	}

}

::GUI::init
