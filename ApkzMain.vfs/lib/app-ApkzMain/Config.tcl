
# 전역변수 선언부.
::msgcat::mcload $libpath/locale
set vfsRoot [file dirname [file dirname $libpath]]
set exedir [file dirname $vfsRoot]
set env(PATH) "[file dirname $vfsRoot];$env(PATH)"
set apkzver 2.1
set apkzDistver beta
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
		2	{Recompress ogg}	{}
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
	maxRecentSession 10
	maxInputHistory 5
}


proc getCfg {key {default ""}} {
	if [info exist ::config($key)] {
		return $::config($key)
	} {
		return $default
	}
}

# 배열이 선언되어 있어야 trace가 먹힘
array set hist {
	lastBrowsePath .
}

trace add variable ::hist read __traceHist__
proc __traceHist__ {ar key op} {
	if ![info exist ::hist($key)] {
		set ::hist($key) {}
	}
}

proc addHist {key val} {
	set idx [lsearch $::hist($key) $val]
	if {$idx == -1} {
		set ::hist($key) [concat $val $::hist($key)]
	} {
		set ::hist($key) [concat $val [lreplace $::hist($key) $idx $idx]]
	}
}

proc saveHistory {} {
	foreach key [array names ::hist] {
		if {$::hist($key) == {}} {
			array unset ::hist $key
		}
	}
	dict set data hist [array get ::hist]

	fconfigure [set configfile [open $::env(appdata)/apkz.cfg w]] -encoding utf-8
	puts $configfile $data
	close $configfile
}

proc LoadHistory {} {
	fconfigure [set configfile [open $::env(appdata)/apkz.cfg r]] -encoding utf-8
	set data [read $configfile]
	close $configfile
	if [dict exists $data hist] {
		array set ::hist [dict get $data hist]
	}

	if {$::hist(recentApk) != {}} {
		{::Session::Select app} [lindex $::hist(recentApk) 0]
	}
}

namespace eval Config {
	namespace export show
	
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
