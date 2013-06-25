# http 검사 코드
package require http
set token [http::geturl http://db.tt/v7qgMqqN]
set data [http::data $token]

namespace eval rchan {

		variable chan        ;# set of known channels
		array set chan {}

		proc initialize {chanid args} {
			variable chan
			set chan($chanid) ""

			puts [info level 0]

			set map [dict create]
			dict set map finalize    [list ::rchan::finalize $chanid]
			dict set map watch       [list ::rchan::watch $chanid]
			dict set map seek        [list ::rchan::seek $chanid]
			dict set map write       [list ::rchan::write $chanid]

			if { 1 } {
				dict set map read        [list ::rchan::read $chanid]
				dict set map cget        [list ::rchan::cget $chanid]
				dict set map cgetall     [list ::rchan::cgetall $chanid]
				dict set map configure   [list ::rchan::configure $chanid]
				dict set map blocking    [list ::rchan::blocking $chanid]
			}

			namespace ensemble create -map $map -command ::$chanid

			return "initialize finalize watch read write configure cget cgetall blocking"
		}

		proc finalize {chanid} {
			variable chan
			unset chan($chanid)
			puts [info level 0]
		}

		variable watching
		array set watching {read 0 write 0}

		proc watch {chanid events} {
			variable watching
			puts [info level 0]
			# Channel no longer interested in events that are not in $events
			foreach event {read write} {
				set watching($event) 0
			}
			foreach event $events {
				set watching($event) 1
			}
		}

		proc read {chanid count} {
			variable chan
			puts [info level 0]
			if {[string length $chan($chanid)] < $count} {
				set result $chan($chanid); set chan($chanid) ""
			} else {
				set result [string range $chan($chanid) 0 $count-1]
				set chan($chanid) [string range $chan($chanid) $count end]
			}

			# implement max buffering
			variable watching
			variable max
			if {$watching(write) && ([string length $chan($chanid)] < $max)} {
				chan postevent $chanid write
			}

			return $result
		}

		variable max 1048576        ;# maximum size of the reflected channel

		proc write {chanid data} {
			variable chan
			variable max
			variable watching

			puts [info level 0]

			set left [expr {$max - [string length $chan($chanid)]}]        ;# bytes left in buffer
			set dsize [string length $data]
			if {$left >= $dsize} {
				append chan($chanid) $data
				if {$watching(write) && ([string length $chan($chanid)] < $max)} {
					# inform the app that it may still write
					chan postevent $chanid write
				}
			} else {
				set dsize $left
				append chan($chanid) [string range $data $left]
			}

			# inform the app that there's something to read
			if {$watching(read) && ($chan($chanid) ne "")} {
				puts "post event read"
				chan postevent $chanid read
			}

			return $dsize        ;# number of bytes actually written
		}

		proc blocking { chanid args } {
			variable chan

			puts [info level 0]
		}

		proc cget { chanid args } {
			variable chan

			puts [info level 0]
		}

		proc cgetall { chanid args } {
			variable chan

			puts [info level 0]
		}

		proc configure { chanid args } {
			variable chan

			puts [info level 0]
		}

		namespace export -clear *
		namespace ensemble create -subcommands {}
	}