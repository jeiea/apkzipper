package provide app-ApkzMain 1.0

set libpath [file dirname [info script]]
lappend auto_path [file dirname $libpath]

package require Tcl
package require Tk
package require twapi
package require tkdnd
package require tooltip
package require msgcat 1.4.4
package require http
namespace import ::msgcat::mc
namespace import ::tcl::prefix

# �������� �����.
# TODO: �� ��θ� ����� ��ġ��. ������ ������ϰ� ���������ϰ� �ٸ� ��� ��ó�ϱ� ���� ������ ����.
::msgcat::mcload $libpath/locale
set vfsdir [file dirname [file dirname $libpath]]
set exedir [file dirname $vfsdir]
set env(PATH) "[file dirname $vfsdir];$env(PATH)"
set apkzver 2.0
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
	mod1	<1>
	mod2	<ButtonRelease-3>
	actionAfterConnect {}
	enableHistory true
	installConserveData -r
	uninstallConserveData -k
	askExtension {}
	maxRecentSession 10
	maxInputHistory 5
}

array set hist {
	recentApk {}
	ip {}
}


source $libpath/Utility.tcl
source $libpath/ApkzGUI.tcl
if [string match *wish.exe [info nameofexecutable]] {
	source $libpath/ApkzDbg.tcl
}
bind .p.f2.fLog.sb <Shift-3> {
	catch {console show}
}

catch {
	set data [dict create]
	fconfigure [set configfile [open $env(appdata)/apkz.cfg r]] -encoding utf-8
	set data [read $configfile]
	close $configfile
	if [dict exists $data hist] {
		array set ::hist [dict get $data hist]
	}
}

if {$::hist(recentApk) != {}} {
	{::ModApk::Select app} [lindex $::hist(recentApk) 0]
}

# �ӽ����� ����
bindtags . MAINWIN
bind MAINWIN <Destroy> {
	foreach fileName [array names vfsMap] {
		file delete $vfsMap($fileName)
	}

	set data [dict create]
	dict set data hist [array get ::hist]
	catch {
		fconfigure [set configfile [open $env(appdata)/apkz.cfg w]] -encoding utf-8
		puts $configfile $data
		close $configfile
	}
}
