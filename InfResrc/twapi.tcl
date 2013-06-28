package require twapi
twapi::export_public_commands
namespace import twapi::*
twapi::allocate_console
set cin [twapi::get_console_handle stdin]
set cout [twapi::get_console_handle stdout]
set hStdin [twapi::get_standard_handle stdin]
set hStdout [twapi::get_standard_handle stdout]
set hStderr [twapi::get_standard_handle stderr]
# twapi::set_standard_handle TYPE HANDLE
set dupin  [twapi::duplicate_handle $hStdin]
set dupout [twapi::duplicate_handle $hStdout]
set duperr [twapi::duplicate_handle $hStderr]

lassign [chan pipe] inr inw
lassign [chan pipe] outr outw
lassign [chan pipe] errr errw
chan configure $inr -blocking false -buffering line
chan configure $outr -blocking false -buffering line
chan configure $errr -blocking false -buffering line
set inrHandle [twapi::get_tcl_channel_handle $inr read]
set outwHandle [twapi::get_tcl_channel_handle $outw write]
set errwHandle [twapi::get_tcl_channel_handle $errw write]

#set_standard_handle stdin  $dupin
set_standard_handle stdout $outwHandle
#set_standard_handle stderr $duperr

# twapi::duplicate_handle HANDLE ?options? 
lassign [twapi::create_process {} -cmdline cmd.exe -showwindow hidden\
	-inherithandles true -detached 0] pid

# set hProc [twapi::get_process_handle [pid] -access generic_all]
set_standard_handle stdin  $dupin
set_standard_handle stdout $hStdout
set_standard_handle stderr $duperr


lassign [twapi::create_process {} -cmdline [getVFile 7za.exe] -showwindow hidden\
	-inherithandles true -detached 0 -stdhandles [list $inrHandle $outwHandle $errwHandle]] pid
#lassign [twapi::create_process {} -cmdline [getVFile 7za.exe] -showwindow hidden\
	-inherithandles true -detached 0 -stdchannels [list $inr $outw $errw]] pid
#lassign [twapi::create_process {} -cmdline [getVFile 7za.exe] -showwindow hidden\
	-inherithandles true -detached 0] pid
