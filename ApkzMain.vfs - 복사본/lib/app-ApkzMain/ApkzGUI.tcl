
wm title . [mc APKZIPPER]
. config -menu [menu .mbar]

.mbar add cascade -label [mc CONFIG] -menu [menu .mbar.config]
.mbar.config add cascade -label [mc ZIP_LEVEL] -menu [menu .mbar.config.zlevel -tearoff 0]
foreach idx [seq 10] {.mbar.config.zlevel add radiobutton -label [mc ZLEVEL$idx] -value $idx -variable zlevel}
.mbar.config add cascade -label [mc DECOMPILE_OPTION] -menu [menu .mbar.config.target -tearoff 0]
.mbar.config.target add radiobutton -label [mc SOURCES] -variable decopt -value "-r"
.mbar.config.target add radiobutton -label [mc RESOURCES] -variable decopt -value "-s"
.mbar.config.target add radiobutton -label [mc BOTH] -variable decopt -value " "
.mbar.config.target add radiobutton -label [mc THE_OTHERS] -variable decopt -value "-r -s"

.mbar add cascade -label [mc SDK_FUNCTION] -menu [menu .mbar.sdk]
.mbar.sdk add command -label [mc ADB_SHELL] -command {Adb version; exec cmd /C "[GetVFile adb.exe] shell" &}
.mbar.sdk add command -label [mc TAKE_PHONE_LOG] -command {Adb_logcat}
.mbar.sdk add command -label [mc ADB_CONNECT] -command {Adb_connect}
.mbar.sdk add command -label [mc REBOOT]
.mbar.sdk add command -label [mc ENTER_RECOVERY]
.mbar.sdk add command -label [mc FLASH_RECOVERY]
.mbar.sdk add command -label [mc ENTER_DOWNLOAD]

.mbar add cascade -label [mc ETC_FUNCTION] -menu [menu .mbar.etc -tearoff 0]
.mbar.etc add command -label [mc CHECK_UPDATE]
.mbar.etc add cascade -label [mc CLEAN_FOLDER] -menu [menu .mbar.etc.clean -tearoff 0]
foreach item {DELETE_CURRENT_RESULT DELETE_CURRENT_WORKDIR DELETE_CURRENT_EXCEPT_ORIGINAL DELETE_CURRENT_ALL
			  DELETE_ALL_RESULT DELETE_ALL_WORKDIR DELETE_ALL_EXCEPT_ORIGINAL DELETE_ALL} {
	.mbar.etc.clean add command -label [mc $item] -command {Clean_folder $item}
}
.mbar.etc add command -label [mc VISIT_WEBSITE]
.mbar.etc add command -label [mc HELP]

pack [ttk::label .lApp -textvariable capps] -fill x -side top
pack [ttk::panedwindow .p -orient vertical] -padx 3 -pady 3 -expand 1 -fill both -side bottom
.p add [ttk::frame .p.f1 -relief solid]
.p add [ttk::labelframe .p.f2 -width 100 -height 100]
grid rowconfigure .p.f1 1 -weight 1
grid columnconfigure .p.f1 [seq 5] -weight 1

foreach framename {fImport fDec fOperate fEnc fExport} {
	lappend frames [ttk::frame .p.f1.$framename]
}
pack [ttk::frame .p.f2.fLog] -side top -expand 1 -fill both
pack [text .p.f2.fLog.tCmd -width 0 -height 0 -yscrollcommand ".p.f2.fLog.sb set " -wrap char] -side left -fill both -expand 1
pack [ttk::scrollbar .p.f2.fLog.sb -orient vertical -command ".p.f2.fLog.tCmd yview "] -side right -fill both
foreach ideal {"³ª´®°íµñÄÚµù" "¸¼Àº °íµñ" "Consolas" "µ¸¿òÃ¼"} {
	if {[lsearch [font families] $ideal] != -1} {
		.p.f2.fLog.tCmd config -font [list $ideal 9]
		break
	}
}
bind .p.f2.fLog.tCmd <KeyPress> {
	focus .p.f2.ePrompt
	event generate .p.f2.ePrompt <KeyPress> -keycode %k
}
.p.f2.fLog.tCmd config -state disabled

pack [ttk::entry .p.f2.ePrompt] -fill x -side bottom
bind . <FocusIn> {
	if {[string first "%W" ".p.f2.fLog.tCmd"] == -1} {
		focus .p.f2.ePrompt
	}
}
bind .p.f2.ePrompt <Return> {
	set cmd [.p.f2.ePrompt get]
	if {$cmd != ""} {
		.p.f2.ePrompt delete 0 end
		CommandParser $cmd
	}
}
focus .p.f2.ePrompt

proc Print data {
	.p.f2.fLog.tCmd config -state normal
	.p.f2.fLog.tCmd insert end $data
	.p.f2.fLog.tCmd yview end
	.p.f2.fLog.tCmd config -state disabled
}

grid {*}$frames -row 1 -sticky news
foreach fram $frames {
	grid columnconfigure $fram 0 -weight 1
}

set btns [list \
.p.f1.fImport.bPull     [mc IMPORT_FROM_PHONE] Adb_pull       \
.p.f1.fImport.bSelFile  [mc SELECT_APP]        Select_app     \
.p.f1.fDec.bExtract     [mc EXTRACT]           Extract        \
.p.f1.fDec.bDecompile   [mc DECOMPILE'N'INSTALL_FRAMEWORK] Decompile \
.p.f1.fOperate.bFolder  [mc OPEN_FOLDER]       Explore_project\
.p.f1.fOperate.bOptipng [mc OPTIMIZE_PNG]      Optimize_png   \
.p.f1.fOperate.bSoxogg  [mc RECOMPRESS_OGG]    Squeeze_ogg    \
.p.f1.fEnc.bCompress    [mc ZIP]               Zip            \
.p.f1.fEnc.bCompile     [mc COMPILE]           Compile        \
.p.f1.fEnc.bSign        [mc SIGN]              Sign           \
.p.f1.fExport.bInstall  [mc INSTALL]           Adb_install    \
.p.f1.fExport.bPush     [mc PUSH_TO_PHONE]     Adb_push]
set count 0
foreach {path title proc} $btns {
	grid [ttk::button $path -text "$count. $title" -command "TraverseCApp $proc"] -padx 5 -sticky news
	incr count
}
unset count
foreach fram [winfo children .p.f1] {
	grid rowconfigure $fram [seq [llength [winfo children $fram]]] -weight 1
}
bind .p.f1.fDec.bDecompile <3> Install_framework
wm minsize . 450 200
wm geometry . 640x480
