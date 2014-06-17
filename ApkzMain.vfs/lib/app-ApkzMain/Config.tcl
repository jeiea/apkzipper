
# �������� �����.
::msgcat::mcload $libpath/locale
set vfsRoot [file dirname [file dirname $libpath]]
set exeDir [file dirname $vfsRoot]
set env(PATH) "$exeDir;$env(PATH)"
array set configDefault {
	zlevel	9
	decomTargetOpt	"     "
	verbose Debug
	btns {
		0	{Import from phone}	{}
		0	{Select app}		{Select app recent}
		1	{Extract}			{}
		1	{Decompile}			{Install framework}
		2	{Explore project}	{Explore app dir}
		2	{Optimize png}		{View java source}
		2	{Deodex}			{Dex}
		3	{Zip}				{Zipalign}
		3	{Compile}			{System compile}
		3	{Sign}				{Explore dex dir}
		4	{Install}			{}
		4	{Export to phone}	{}
	}
	mod1	<ButtonRelease-1>
	mod2	<ButtonRelease-3>
	preferedFont {}
	enableHistory true
	installConserveData -r
	uninstallConserveData -k
	permitExtension 1
	maxHistory 5
	autoUpdate 1
	rememberWindowPos true
	viewMode tutorialView
	conInputMode {-echoinput 1 -quickeditmode 1 -windowinput 0
		-lineinput 1 -processedinput 1 -mouseinput 1
		-autoposition 0 -extendedmode 1 -insertmode 1}
	projectLoc {./projects}
}
array set config [array get configDefault]

namespace eval Config {
	namespace export addHist saveConfig loadConfig getcfg setcfg showDialog
	variable fileSignature {Apkz Config File}
	variable visible? false
	
}

# �迭�� ����Ǿ� �־�� trace�� ����
array set histDefault {
	lastBrowsePath .
	mainWinPos 640x480
}
array set hist [array get histDefault]

# �߰��ϸ� �˾Ƽ� �� ó�� �׸����� �߰��ǵ��� �����Ѵ�.
# �ִ� �׸� ���� �� �ѵ��� ����.
trace add variable ::hist read Config::__traceHist__
proc Config::__traceHist__ {ar key op} {
	if ![info exist ::hist($key)] {
		set ::hist($key) {}
	}
}

# ���⿡�� �ߺ����Ÿ� ó����Ű���� �˾Ƽ� ���� ������ �ڷ�� ������ val�� �Ѱ����.
proc Config::addHist {key val} {
	set idx [lsearch -exact $::hist($key) $val]
	if {$idx == -1} {
		set ::hist($key) [concat [list $val] $::hist($key)]
	} {
		set ::hist($key) [concat [list $val] [lreplace $::hist($key) $idx $idx]]
	}
	if {[llength $::hist($key)] >= $::config(maxHistory)} {
		set ::hist($key) [lrange $::hist($key) 0 $::config(maxHistory)-1]
	}
	saveConfig
}

# �������� ��ο� ���������� ������, �� ���������� ��.
proc Config::getConfigFilePath {} {
	if [file exist $::exeDir/apkz.cfg] {
		set path $::exeDir/apkz.cfg
	} {
		set path $::env(appdata)/apkz.cfg 
	}
	return [file normalize $path]
}

proc Config::saveConfig {} {
	variable fileSignature

	if $::config(enableHistory) {
		foreach key [array names ::hist] {
			if {$::hist($key) == {}} {
				array unset ::hist $key
			}
		}
		dict set data hist [array get ::hist]
	}
	dict set data config [array get ::config]

	fconfigure [set configfile [open [getConfigFilePath] w]] -encoding utf-8
	catch {puts $configfile "$fileSignature $::apkzver"} err errinfo
	puts $configfile $data
	close $configfile
}

proc Config::getMinorVersion {version subver} {
	return [join [lrange [split $version .] 0 $subver] .]
}

# subver�� ���� ������, ���̳ʹ����� ���� �� ����.
proc Config::vcompare {a b subver} {
	return [package vcompare [getMinorVersion $a $subver] [getMinorVersion $b $subver]]
}

proc Config::loadConfig {} {
	variable fileSignature

	try {
	fconfigure [set configfile [open [getConfigFilePath] r]] -encoding utf-8
	if {[scan [gets $configfile] "$fileSignature %s" fileVer] != 1} {
		return
	}
	set data [read $configfile]
	close $configfile

	# ������ ���� ��
	if {[vcompare $fileVer $::apkzver 0] != 0} {
		tk_messageBox -title [mc {Notice}] -message [concat \
			[mc {Config file of not compatible version was found.}]\n \
			[mc {Due to major version difference, it'll use default setting.}]\n
			[mc {Keep in mind that settings will be overwritten when termination.}]
		error
	}
	# ���̳� ���� ��
	if {[vcompare $fileVer $::apkzver 1] > 0} {
		tk_messageBox -title [mc {Notice}] -message [concat \
			[mc {Config file of different version was found.}]\n \
			[mc {If problem occurs, you can use reset function.}]\n]
	}

	if [dict exists $data hist] {
		array set ::hist [dict get $data hist]
	}
	if [dict exists $data config] {
		array set ::config [dict get $data config]
		foreach key [array names configDefault] {
			if {[array names ::config $key] eq {}} {
				set ::config($key) $::configDefault($key)
			}
		}
	}

	} trap {POSIX ENOENT} {} {
		puts $::wrVerbose [mc {It seems config file not exists. }][mc {Default applied.}]
	} on error {msg info} {
		puts $::wrVerbose [mc {Error opening config file: %s} $info]\n[mc {Default applied.}]
		array set ::config [array get ::configDefault]
	} finally {
#	������ �ִٸ� ��������� ������ ��.
		if [catch applyConfig] {
			array set ::config [array get ::configDefault]
			applyConfig
		}
	}
}

# �⺻ ������ ���� �ʱ�ȭ �۾�
proc applyConfig {} {
	set taskMap {
		::config(autoUpdate) {
			if $::config(autoUpdate) {
				after 100 { {::Check update} business }
			}
		}
		::config(verbose) {
			::View::textcon.verbose $::config(verbose)
		}
		::hist(recentApk) {
			if ![string is space [lindex $::hist(recentApk) 0]] {
				{::Select app} business {*}[lindex $::hist(recentApk) 0]
			}
		}
		::config(viewMode) {
			.mbar entryconf 4 {*}[::View::menuUnderline [mc [::View::switchView $::config(viewMode)]]]
		}
		::hist(mainWinPos) {
			wm geometry . $::hist(mainWinPos)
			bind MAINWIN <Configure> {
				set ::hist(mainWinPos) [wm geometry .]
			}
		}
	}
	foreach {key task} $taskMap {
		try {
			if {[info exist $key]} {
				eval $task
			}
		}
	}
}

proc Config::regenerateDialog {} {
	set geom [wm geometry .config]
	puts $geom
	destroy .config
	Config::showDialog $geom
}

proc fontchooserDemo {} {
	button .b -command fontchooserToggle -takefocus 0
	fontchooserVisibility .b
	foreach w {.t1 .t2} {
		text $w -width 20 -height 4 -borderwidth 1 -relief solid
		bind $w <FocusIn> [list fontchooserFocus $w]
		$w insert end "Text Widget $w"
	}
	.t1 configure -font {Courier 14}
	.t2 configure -font {Times 16}
	pack .b .t1 .t2; focus .t1
}

proc Config::FontDialogListener {win font args} {
	$win config -font [font actual $font]
	set ::fontBtnText [getWidgetFont $win]
}

proc Config::showFontDialog {w} {
	tk fontchooser configure -font [$w cget -font] \
		-command [list Config::FontDialogListener $w]
	tk fontchooser show
}

proc getWidgetFont {w} {
	set fontIntro [font actual [$::View::tCon cget -font] -family]
	append fontIntro ", [font actual [$::View::tCon cget -font] -size]"
	return $fontIntro
}

coproc Config::showDialog {{location ""}} {
	if [winfo exists .config] {
		raise .config
		return
	}
	toplevel .config
	wm title .config [mc Config]
	if {$location ne {}} {
		puts "catch: $geom"
		wm geometry .config $location
	}

	pack [set nb [ttk::notebook .config.notebook]] -fill both -expand true
	pack [ttk::button .config.cancel -text [mc Cancel]	-command {destroy .config}] -side right
	pack [ttk::button .config.ok	 -text [mc OK	 ]	-command [info coroutine]] -side right
	pack [ttk::button .config.reset	 -text [mc {Reset to previous}] \
		-command ::Config::regenerateDialog] -side left
	
	$nb add [set tuner [ttk::frame $nb.tuner]] -text [mc {Tuner}]
	$nb select $tuner
	
	# �̷� ��� �ߺ� ���Ű� �����Ϸ���... �ϴ� ���߿� plugin���� ���쵵�� �� ��츦 �����
	# �ߺ��� ���ܵ����� �� ����.

	# ���༼�� ����
	set zlevels [lmap i [seq 10] {mc "Ziplevel $i"}]
	set lbZLevel [ttk::label $tuner.lbZLevel -text [mc {Ziplevel:}]]
	set cbZLevel [ttk::combobox $tuner.cbZlevel -values $zlevels -state readonly]
	$cbZLevel current $::config(zlevel)
	
	# ���Ŀɼ� ����
	set decOptMap {
		{-r   }	{Sources}
		{-s   }	{Resources}
		{     }	{Both}
		{-r -s}	{The others}
	}
	set decOptLocalLabels [lmap opt [dict values $decOptMap] {mc $opt}]
	set lbTarget [ttk::label $tuner.lbTarget -text [mc {Decompile target:}]]
	set cbTarget [ttk::combobox $tuner.cbtarget -values $decOptLocalLabels -state readonly]
	$cbTarget current [lsearch [dict keys $decOptMap] $::config(decomTargetOpt)]
	
	# �α׷���
	set logLevels {Error Warning Info Debug}
	set localized [lmap level $logLevels {mc $level}]
	set lbVerbose [ttk::label $tuner.lbVerbose -text [mc {Log level:}]]
	set cbVerbose [ttk::combobox $tuner.cbVerbose -values $localized -state readonly]
	$cbVerbose current [lsearch $logLevels $::config(verbose)]
	
	# Ȯ���� �ٸ����� �߰�Ȯ��
	set lbExtConfirm [ttk::label $tuner.lbExtConfirm -text [mc {Operation to other extension:}]]
	set cbExtConfirm [ttk::combobox $tuner.cbExtConfirm \
		-values [lmap str {Ask {Yes to all} {No to all}} {mc $str}] -state readonly]
	$cbExtConfirm current [expr {$::config(permitExtension) - 1}]
	
	# ������Ʈ���� ��ġ ����
	set projLocEnum [list [file nativename ./projects] \
		[mc {Executable directory}] [mc {Apk directory}]]
	set lbProjLoc [ttk::label $tuner.lbProjLoc -text [mc {Project location:}]]
	set cbProjLoc [ttk::combobox $tuner.cbProjLoc -values $projLocEnum -textvariable ::cbProj]
	switch $::config(projectLoc) {
		{Executable directory} {
			$cbProjLoc current 1
		}
		{Apk directory} {
			$cbProjLoc current 2
		}
		default {
			set ::cbProj [file nativename $::config(projectLoc)]
		}
	}
	
	# �ڵ� ����, ��Ʈ
	global bAutoup
	set bAutoup $::config(autoUpdate) 
	set btnAutoup [ttk::checkbutton $tuner.btnAutoup -text [mc {Auto update}] -variable ::bAutoup]
	
	tk fontchooser configure -parent .config
	set ::fontBtnText [getWidgetFont $::View::tCon]
	set btnFont [ttk::button $tuner.btnFont -textvariable ::fontBtnText \
		-command [list Config::showFontDialog $::View::tCon]]
	
	# ��ġ
	grid $lbZLevel $cbZLevel -padx 3 -pady 2
	grid $lbTarget $cbTarget -padx 3 -pady 2
	grid $lbVerbose $cbVerbose -padx 3 -pady 2
	grid $lbExtConfirm $cbExtConfirm -padx 3 -pady 2
	grid $lbProjLoc $cbProjLoc -padx 3 -pady 2
	grid $btnAutoup $btnFont -padx 3 -pady 2 -sticky we
	
	# â�� ������ �ڷ�ƾ ����
	bindtags .config [concat [bindtags .config] ConfigToplevel]
	bind ConfigToplevel <Destroy> [format {
		rename {%s} {}
	} [info coroutine]]

	# ���
	set answer [yield]
	
	# �� ����
	set ::config(zlevel) [$cbZLevel current]
	set ::config(decomTargetOpt) [lindex [dict keys $decOptMap] [$cbTarget current]]
	set ::config(verbose) [lindex $logLevels [$cbVerbose current]]
	::View::textcon.verbose $::config(verbose)
	set ::config(autoUpdate) $bAutoup
	set ::config(preferedFont) [getWidgetFont $::View::tCon]
	set ::config(permitExtension) [expr {[$cbExtConfirm current] + 1}]
	switch $::cbProj [list \
		[mc {Executable directory}] {
			set ::config(projectLoc) {Executable directory}
		} \
		[mc {Apk directory}] {
			set ::config(projectLoc) {Apk directory}
		} \
		default {
			while {[catch {
				set newProjDir [file join $::cbProj projects]
				file mkdir $newProjDir
			}]} {
				tk_messageBox -title Warning -message {Project path is invalid. Please check again.}
				yield
			}
			set ::config(projectLoc) $::cbProj
		}
	]

	unset ::cbProj
	unset ::bAutoup
	bind ConfigToplevel <Destroy> {}
	destroy .config
}

namespace import Config::*
