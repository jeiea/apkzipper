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

loadConfig
after 100 {
	{::Check update} business
}

bind .p.f2.fLog.sb <Control-Shift-3> {
	catch {console show}
}

# 임시파일 제거
bind MAINWIN <Destroy> {+
	catch {
		cleanupVFile
		saveConfig
	}
	exit
}
