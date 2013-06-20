package provide app-ApkzMain 2.2

set libpath [file dirname [info script]]
lappend auto_path [file dirname $libpath]
tk appname ApkZipper2

package require Tcl
package require twapi
package require tkdnd
package require tooltip
package require msgcat
package require http
package require TclOO
package require Thread
namespace import ::msgcat::mc
namespace import ::tcl::prefix

bindtags . MAINWIN

source $libpath/PluginBase.tcl
source $libpath/Plugins.tcl
source $libpath/Utility.tcl
source $libpath/Config.tcl
source $libpath/View.tcl
source $libpath/WinADB.tcl
source $libpath/Session.tcl
if [regexp {.*wish(86)?\.exe$} [info nameofexecutable]] {
	source $libpath/ApkzDbg.tcl
}
bind .p.f2.fLog.sb <Control-Shift-3> {
	catch {console show}
}

loadConfig
# 기본 설정에 따른 초기화 작업
if $config(autoUpdate) {
	after 100 {
		{::Check update} business
	}
}
if {$::hist(recentApk) ne {}} {
	{::Session::Select app} [lindex $::hist(recentApk) 0]
}
if {$::hist(mainWinPos) ne {}} {
	wm geometry . $::hist(mainWinPos)
	bind MAINWIN <Configure> {
		set ::hist(mainWinPos) [wm geometry .]
	}
}

# 임시파일 제거 등 정리작업
bind MAINWIN <Destroy> {+
	catch {
		cleanupVFile
		saveConfig
	}
	exit
}
