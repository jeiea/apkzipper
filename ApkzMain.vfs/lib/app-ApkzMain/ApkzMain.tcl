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

# 전역변수 선언부.
# TODO: 이 경로를 제대로 고치기. 지금은 디버그하고 실행파일하고 다른 경우 대처하기 위해 절대경로 땜빵.
::msgcat::mcload $libpath/locale
set vfsdir [file dirname [file dirname $libpath]]
set exedir [file dirname $vfsdir]
set env(PATH) "[file dirname $vfsdir];$env(PATH)"
set apkzver 0.1
array set config {
	zlevel	9
	decomTargetOpt	"     "
	verbose	true
	btns {
		0	{Import from phone}	{}
		0	{Select app}		{Select app recent}
		1	{Extract}			{}
		1	{Decompile}			{Install framework}
		2	{Explore project}	{}
		2	{Optimize png}		{}
		2	{Recompress ogg}	{}
		3	{Zip}				{}
		3	{Compile}			{Zipalign}
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
}

array set hist {
	recentApk {}
	ip {}
}

source $libpath/Utility.tcl
source $libpath/ApkzDbg.tcl
source $libpath/ApkzGUI.tcl

# 임시파일 제거
bindtags . MAINWIN
bind MAINWIN <Destroy> {
	foreach fileName [array names vfsMap] {
		file delete $vfsMap($fileName)
		puts $vfsMap($fileName)
	}
}
