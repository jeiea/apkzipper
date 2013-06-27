package provide app-ApkzMain 2.3

set libpath [file dirname [info script]]
lappend auto_path [file dirname $libpath]
tk appname ApkZipper2

package require Tcl 8.6
package require TclOO
package require Thread
package require http
package require msgcat
package require twapi
package require tooltip
package require tcl::transform::observe
package require tls
package require autoproxy
namespace import ::msgcat::mc
namespace import ::tcl::prefix

bindtags . [concat [bindtags .] MAINWIN]

source $libpath/PluginBase.tcl
source $libpath/Plugins.tcl
source $libpath/Utility.tcl
source $libpath/Config.tcl
source $libpath/View.tcl
source $libpath/WinADB.tcl
source $libpath/Session.tcl
if [regexp {.*wish(86)?\.exe$} [info nameofexecutable]] {
	source $::exeDir/InfResrc/ApkzDbg.tcl
}

autoproxy::init
http::register https 443 ::autoproxy::tls_socket
View::init
loadConfig

bind .bottomConsole.sb <Control-Shift-3> {
	catch {console show}
}
# 임시파일 제거 등 정리작업
bind MAINWIN <Destroy> {+
	catch {
		cleanupVFile
		saveConfig
	}
	exit
}
