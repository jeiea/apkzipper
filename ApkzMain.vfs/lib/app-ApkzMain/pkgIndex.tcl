
set apkzver 2.1
package ifneeded app-ApkzMain $apkzver " \
	source [file join $dir ApkzMain.tcl]; \
	package provide app-ApkzMain $apkzver "
