package provide app-ApkzMain 1.0

package require Tcl 8.5
package require Tk 8.5.11
package require msgcat 1.4.4
namespace import ::msgcat::mc
namespace import ::tcl::prefix

# �������� �����.
# TODO: �� ��θ� ����� ��ġ��. ������ ������ϰ� ���������ϰ� �ٸ� ��� ��ó�ϱ� ���� ������ ����.
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

# �ӽ����� ����
bindtags . MAINWIN
bind MAINWIN <Destroy> {
	foreach fileName [array names vfsMap] {
		file delete $vfsMap($fileName)
		puts $vfsMap($fileName)
	}
}
