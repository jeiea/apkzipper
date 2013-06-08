package provide app-ApkzMain 2.1

set libpath [file dirname [info script]]
lappend auto_path [file dirname $libpath]

package require Tcl
package require Tk
package require twapi
package require tkdnd
package require tooltip
package require msgcat
package require http
package require TclOO
namespace import ::msgcat::mc
namespace import ::tcl::prefix


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

LoadHistory

bind .p.f2.fLog.sb <Control-Shift-3> {
	catch {console show}
}

# 임시파일 제거
bindtags . MAINWIN
bind MAINWIN <Destroy> {
	cleanupVFile
	saveHistory
}
