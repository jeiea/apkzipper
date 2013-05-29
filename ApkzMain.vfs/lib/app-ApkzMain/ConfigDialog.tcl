#!/bin/sh
# SettingDialog.tcl \
exec tclsh "$0" ${1+"$@"}

namespace eval Configuration {
	namespace export show
	
	variable visible? false
	
	proc show {} {
		toplevel .config
		
		pack [set nb [ttk::notebook .config.notebook]]
		$nb add [set tuner [ttk::frame $nb.tuner]] -text [mc {Tuner}]
		$nb select $tuner
		grid [ttk::combobox $tuner.cbZlevel]
		for {set i 0} {i < 10} {incr i} {$tuner.cbZlevel add $i}
		
	}
	
	[mc asdf]
}