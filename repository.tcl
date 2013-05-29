# 차라리 GetAlternateName이 나았으려나. 근데 이건 지극히 사적인 소스로 가정, preproc은 .이 현재함수, ..이 본래함수가 되겠다.
proc preproc {procname arg body} {
	uplevel {
		set newname Tempfunc_[expr rand()]
		while {
			[llength [info commands $newname]]  ||
			[llength [info functions $newname]] ||
			[llength [info procs $newname]]
		} {
			set newname Tempfunc_[expr rand()]
		}
		regsub -all -line -linestop ^\\s*\[\{\[;\]*\\s*(.)\\s $newname
		rename procname $newname
		rename $newname {}
		
	}
}

preproc exec {
	
}

# 임시 UI


set mainBtnItem {
	ADB_POP EXTRACT SELECT_APP DECOMPILE COMPILE ZIP SYSTEM_COMPILE COMPRESSION_LEVEL JAVA_HEAP_SIZE
	DECOMPILE_TARGET INSTALL_FRAMEWORK SIGN ZIPALIGN ADB_PUSH ADB_INSTALL EXPLORE_PROJECT OPTIMIZE_PNG
	SQUEEZE_OGG SWITCH_SIGN ADB_SHELL ADB_READLOG ADB_CONNECT READ_LOG CLEAN_FOLDER TIP_ABOUT
}

foreach translated "$mainBtnItem" {
	lappend mainBtnTitle [mc "$translated"]
}

set numBtn [llength $mainBtnTitle]

pack [ttk::frame .f -width 640 -height 480] -padx 3 -pady 3 -expand 0 -fill both
grid columnconfigure .f 0 -weight 1
grid [ttk::label .f.lAppName -textvariable cAppName -justify right -anchor e] -column 0 -row 0 -sticky news
for {set c 1} {$c < $numBtn} {incr c} {
	grid [ttk::button .f.b$c -text "$c. [lindex $mainBtnTitle $c]" -command "TraverseCApp [string totitle [lindex $mainBtnItem $c]]"] \
		-padx 1 -pady 1 -column 0 -row $c -sticky news
	puts "grid \[ttk::button .f.b$c -text $c. [lindex $mainBtnTitle $c] -command \"TraverseCApp [string totitle [lindex $mainBtnItem $c]]\"]"
	grid rowconfigure .f $c -weight 1
}

# 임시 UI 끝

set btnMenu [list
	[mc ADB_POP]
	[mc EXTRACT]
	[mc SELECT_APP]
	[mc DECOMPILE]
	[mc COMPILE]
	[mc ZIP]
	[mc SYSTEM_COMPILE]
	[mc COMPRESSION_LEVEL]
	[mc JAVA_HEAP_SIZE]
	[mc DECOMPILE_TARGET]
	[mc INSTALL_FRAMEWORK]
	[mc SIGNING]
	[mc ZIPALIGN]
	[mc ADB_PUSH]
	[mc ADB_INSTALL]
	[mc EXPLORE_PROJECT]
	[mc OPTIMIZE_PNG]
	[mc SQUEEZE_OGG]
	[mc RESTORE_REMOVE_SIGN]
	[mc ADB_SHELL]
	[mc ADB_READLOG]
	[mc ADB_CONNECT]
	[mc READ_LOG]
	[mc CLEAN_FOLDER]
	[mc TIP_ABOUT]
	[mc EXIT]
]

#[mc AUTO_ZIP_SIGN_ALIGN_INSTALL]
#[mc AUTO_COMPILE_SIGN_ALIGN_INSTALL]
set mainBtnItemNew {
	PREPARATORY_OP {ADB_POP EXTRACT SELECT_APP DECOMPILE INSTALL_FRAMEWORK}
	MODIFYING_OP {EXPLORE_PROJECT OPTIMIZE_PNG SQUEEZE_OGG RESTORE_REMOVE_SIGN}
	FINALIZING_OP {ZIP COMPILE SYSTEM_COMPILE SIGNING ZIPALIGN ADB_PUSH ADB_INSTALL}
	ADB_OP {ADB_SHELL ADB_READLOG ADB_CONNECT}
	ETC_OP {READ_LOG CLEAN_FOLDER TIP_ABOUT EXIT}
	DECOMPILE_TARGET COMPRESSION_LEVEL JAVA_HEAP_SIZE
}

	foreach path $cAppPath {
		global cApp($count).Name cApp($count).Dir cApp($count).Unsigned cApp($count).Signed
		set cApp($count) $path
		set cApp($count).Name [file nativename [file tail "$cAppPath"]]
		set cApp($count).Dir [file nativename [file dirname "$cAppPath"]]
		set cApp($count).Unsigned [file nativename "$cApp($count).Dir/unsigned_$cApp($count).Name"]
		set cApp($count).Signed [file nativename "$cApp($count).Dir/signed_$cApp($count).Name"]
		incr count
	}
	parray cApp
	
	
	global cAppDict
	set count 0
	foreach path $cAppPath {
		dict append cAppDict $count name [file nativename [file tail "$cAppPath"]]
		dict append cAppDict $count dir [file nativename [file dirname "$cAppPath"]]
		dict append cAppDict $count unsigned [file nativename [file tail [dict with cAppDict "$cAppPath"]]
		dict append cAppDict $count name [file nativename [file tail "$cAppPath"]]
		incr count
	}