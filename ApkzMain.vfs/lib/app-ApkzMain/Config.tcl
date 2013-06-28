
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
	actionAfterConnect {}
	enableHistory true
	installConserveData -r
	uninstallConserveData -k
	askExtension {}
	maxHistory 5
	autoUpdate true
	rememberWindowPos true
	viewMode tutorialView
	conInputMode {-echoinput 1 -quickeditmode 1 -windowinput 0
		-lineinput 1 -processedinput 1 -mouseinput 1
		-autoposition 0 -extendedmode 1 -insertmode 1}
}
array set config [array get configDefault]

namespace eval Config {
	namespace export show addHist saveConfig loadConfig getcfg setcfg
	variable fileSignature {Apkz Config File}
	variable visible? false
	
	proc show {} {
		toplevel .config
		
		pack [set nb [ttk::notebook .config.notebook]]
		$nb add [set tuner [ttk::frame $nb.tuner]] -text [mc {Tuner}]
		$nb select $tuner
		grid [ttk::combobox $tuner.cbZlevel]
		for {set i 0} {i < 10} {incr i} {$tuner.cbZlevel add $i}
	}
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
			after 100 {
				{::Check update} business
			}
		}
		::config(verbose) {
			::View::textcon.verbose $::config(verbose)
		}
		::hist(recentApk) {
			{::Session::Select app} [lindex $::hist(recentApk) 0]
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

namespace import Config::*
