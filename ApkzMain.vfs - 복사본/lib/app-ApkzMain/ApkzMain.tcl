package provide app-ApkzMain 1.0

package require Tcl 8.5
package require Tk 8.5.11
package require msgcat 1.4.4
namespace import ::msgcat::mc
namespace import ::tcl::prefix

# 전역변수 선언부.
# TODO: 이 경로를 제대로 고치기. 지금은 디버그하고 실행파일하고 다른 경우 대처하기 위해 절대경로 땜빵.
set libpath [file dirname [info script]]
::msgcat::mcload $libpath/locale
set vfsdir [file dirname [file dirname $libpath]]
set env(PATH) "[file dirname $vfsdir];$env(PATH)"
set zlevel 9
set decopt " "
set forcedelete -force
console show

source $libpath/Utility.tcl
source $libpath/ApkzGUI.tcl
source $libpath/ApkzSub.tcl
source $libpath/ApkzDbg.tcl

# 임시파일 제거
bindtags . MAINWIN
bind MAINWIN <Destroy> {
	foreach fileName [array names vfsMap] {
		file delete $vfsMap($fileName)
		puts $vfsMap($fileName)
	}
}
