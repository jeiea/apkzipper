# 프로그램 버전은 pkgIndex에서 전적으로 관리.
set ::apkz_ver [package versions app-ApkzMain]

set ::apkz_ver_dist beta

set ::lib_path [file dirname [info script]]
lappend auto_path [file dirname $lib_path]

# 패키지 선언부
package require Tcl 8.6
package require Tk
package require Ttk
package require TclOO
package require Thread
package require http
package require msgcat
package require tooltip
package require tcl::transform::observe
package require tls
package require autoproxy
package require tcl::chan::variable
package require tcl::chan::fifo
package require tcl::chan::memchan
package require tcl::chan::null
package require tcl::transform::observe
package require oo::util
package require yaml

if {$tcl_platform(platform) == {windows}} {
	package require twapi
}

namespace import ::msgcat::mc
namespace import ::tcl::prefix

# 앱 이름 설정
tk appname ApkZipper2

# HTTPS 설정
autoproxy::init
http::register https 443 ::autoproxy::tls_socket

# 소스 인클루드
source -encoding utf-8 $lib_path/PluginBase.tcl
source -encoding utf-8 $lib_path/Plugins.tcl
source -encoding utf-8 $lib_path/Utility.tcl
source -encoding utf-8 $lib_path/Config.tcl
source -encoding utf-8 $lib_path/View.tcl
source -encoding utf-8 $lib_path/WinADB.tcl
source -encoding utf-8 $lib_path/Session.tcl

# 직접 실행 시엔 디버깅 스크립트도 추가로 실행한다.
if [regexp {.*wish(86)?\.exe$} [info nameofexecutable]] {
	source -encoding utf-8 $::exe_dir/ApkzTest/ApkzDbg.tcl
}

# TODO: 여기 의존성 좀 어떻게 처리해야 함. 서로 순서를 못 바꾸는 듯.
View::init
loadConfig

# 스크롤바를 우클릭하면 콘솔 띄우기
bind .bottomConsole.sb <Control-Shift-3> {
	catch {console show}
}

# 프로그램 종료 시 임시파일 제거 등 정리작업
bind . <Destroy> {
	catch {
		cleanupVFile
		saveConfig
	}
	exit
}
