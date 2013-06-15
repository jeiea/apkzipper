
# �������� �����.
::msgcat::mcload $libpath/locale
set vfsRoot [file dirname [file dirname $libpath]]
set exedir [file dirname $vfsRoot]
set env(PATH) "$exedir;$env(PATH)"
array set config {
	zlevel	9
	decomTargetOpt	"     "
	verbose	true
	btns {
		0	{Import from phone}	{}
		0	{Select app}		{Select app recent}
		1	{Extract}			{}
		1	{Decompile}			{Install framework}
		2	{Explore project}	{Explore app dir}
		2	{Optimize png}		{}
		2	{Deodex}			{Odex}
		3	{Zip}				{Zipalign}
		3	{Compile}			{System compile}
		3	{Sign}				{}
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
}

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
array set hist {
	lastBrowsePath .
}

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
}

# �������� ��ο� ���������� ������, �� ���������� ��.
proc Config::getConfigFilePath {} {
	if [file exist $::exedir/apkz.cfg] {
		return $::exedir/apkz.cfg
	} {
		return $::env(appdata)/apkz.cfg 
	}
}

proc Config::saveConfig {} {
	variable fileSignature

	foreach key [array names ::hist] {
		if {$::hist($key) == {}} {
			array unset ::hist $key
		}
	}
	dict set data hist [array get ::hist]

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

	if {$::hist(recentApk) != {}} {
		{::Session::Select app} [lindex $::hist(recentApk) 0]
	}
}

namespace import Config::*
