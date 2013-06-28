
set apkzver 2.3.4

package ifneeded app-ApkzMain $apkzver [format {
	package provide app-ApkzMain %1$s
	set apkzver %1$s
	set apkzDistver beta
	source {%2$s}
} $apkzver [file join $dir ApkzMain.tcl]]
