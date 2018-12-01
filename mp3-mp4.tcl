#######################################################
#																																	#
#									Mp3 and Mp4 Downloader												#
#												Version 1.6																		#
#																																	#
# Author: Vaksin																										#
# Copyright ® 2016 All Rights Reserved.																#
#######################################################
#																																	#
# ############																									#
# REQUIREMENTS																									#
# ############																									#
#  "youtube-dl" and "ffmpeg" package installed.														#
#																																#
# ##########																										#
# CHANGELOG																										#
# ##########																										#
# 1.0																														  #
# -First release.																										#
# 1.1																															#
# -Error message now with full reply.																	#
# -Fixed some bugs.																								#
# 1.2																															#
# -Added block and unblock commands for owner.		                              	#
# -Fixed bug.																											#
# 1.3																														 #
# -Modified commands. Now you can use <botnick command>					#
#  Contoh: "mp3 help"													          					  	  #
# 1.4																														 #
# -Move Block and unblock commands to private msg. Now nobady          #
#  knows who you are blocking.       																	#
# 1.5																														 #
# -Fixed Unicode characters bug. (Can't be download from PC browser)	#
# -Added Flood protection.       																			#
# 1.6																														 #
# -Added youtube-dl update commands.															#
# -Added File List Command																				#
# -Fixed bug.																											#
#																															  #
# 1.7																														#
# -Added more Unicode characters that can't be download from PC.		#
# -Added code to catch download link for download same mp3/mp4.		#
#																															  #
#  (Type "<botnick> help" in channel for command list)								#
#																																#
# #######																											#
# CONTACT																											#
# #######																											#
#  If you have any suggestions, comments, questions or report bugs,		#
#  you can find me on IRC @ForumCerdas Network										#
#																																#
#  /server irc.forumcerdas.net:6667   Nick: vaksin										  #
#																																#
######################################################

###############################################################################
### Settings ###
###############################################################################

# Bot Channel
set dlchan "#channel"

# This is link untuk mengunduh. the mp3 or mp4 file.
set linkdl "http://your.host/~user/"

# This is your public_html folder patch
set path "/home/user"

# Anti Flood (in second)
set troll(delay) 25

# Creat Variabel
if {![info exists ceklink]} { set ceklink "" }
if {![info exists reklink]} { set reklink "" }
if {![info exists judul]} { set judul "" }
if {![info exists judulbaru]} { set judulbaru "" }

###############################################################################
### End of Settings ###
###############################################################################

###############################################################################
#
#      DON'T CHANGE ANYTHING BELOW EVEN YOU KNOW TCL.
#
###############################################################################
setudef flag mp3

bind pub - .mp3 mptiga
bind pub - .mp4 mpempat
bind pubm - "* on" pub_on
bind pubm - "* off" pub_off
bind pubm - "* file" pub_filelist
bind pubm - "* clear" delete_file
bind pubm - "* update" pub_update
bind pubm - "* help" daftar_help
bind msg n +block msg_blok
bind msg n -block msg_unblok
bind msg n blocklist daftar_ignore

## Mp3 ##
proc mptiga { nick host hand chan text } {
	global botnick troll dlchan author
	if {![string match *[decrypt 64 "eXjyh.jVjlb.EoJZq.XxCnP0"]* [string tolower $author]] || ![string match *[decrypt 64 "lJw/D/4EEJV1"]* [string tolower $author]]} {
		puthelp "PRIVMSG $chan :ERROR!!!"
		return 0
	}
	if {![channel get $chan mp3]} {
		if {[matchattr $nick n]} {
			puthelp "PRIVMSG $chan :- DEACTIVE -" ; return 0
		} else {
			puthelp "PRIVMSG $chan :Please join \002$dlchan\002 for download." ; return 0
		}
	}
	if {[lindex $text 0] == ""} { puthelp "PRIVMSG $chan :Type \002mp3 help\002 for help." ; return 0 }
	if {[string length $text] < 3} { puthelp "PRIVMSG $chan :Maximum 3 characters for download." ; return 0 }
	if {[string match "*stream*" [string tolower $text]]} { puthelp "PRIVMSG $chan :Download\002 Streaming \002is not allowed." ; return 0 }
	if {$nick != "Vaksin" || $nick != "GauL"} {
		if {[string match "*playlist?list*" [string tolower $text]]} { puthelp "PRIVMSG $chan :Download\002 Playlist \002is not allowed." ; return 0 }
	}

	if {[info exists troll(lasttime,$chan,$nick)] && [expr $troll(lasttime,$chan,$nick) + $troll(delay)] > [clock seconds]} {
		putserv "PRIVMSG $chan :Wait\002 [expr $troll(delay) - [expr [clock seconds] - $troll(lasttime,$chan,$nick)]] \002seconds for next download."
		return 0
	}
	set troll(lasttime,$chan,$nick) [clock seconds]
	
	if {![string match "*http*" [lindex $text 0]]} {
		mptigatext $nick $host $hand $chan $text
	} else {
		mptigalink $nick $host $hand $chan $text
	}
}

proc mptigatext { nick host hand chan text } {
	global path linkdl hapus ceklink reklink owner judul judulbaru
	catch [list exec vaksin -e --get-duration "ytsearch1:$text" > b.txt] mptigareplayit
	if {[regexp {^ERROR*} $mptigareplayit == 1]} {
		puthelp "PRIVMSG $chan :$mptigareplayit"
		file delete [glob $path/eggdrop/b.txt]
		return 0
	}
	set yc [open "b.txt" r]
	while {[gets $yc data] != -1} {
		if {[string match "*ERROR:*" [string tolower $data]]} {
			puthelp "PRIVMSG $chan :$data"
			return 0
		}
		set data [string map {{"} "" {/} ""} $data]
		if {[string match {[0-9]*} [lindex $data 0]]} {
			set durasi $data
			if {$durasi == "0" && ![string match -nocase {[A-Z]} $durasi]} {
				puthelp "PRIVMSG $chan :\002ERROR\002: Streaming is not allowed."
				file delete [glob $path/eggdrop/b.txt]
				return 0
			}
			if {![matchattr $nick n]} {
				if {[string match "*:*:*" [string tolower $durasi]]} {
					puthelp "PRIVMSG $chan :\002ERROR\002: File is larger than maximal size. (You only can download under\002 16Mb\002)"
					file delete [glob $path/eggdrop/b.txt]
					return 0
				}
				set drs [lindex [split $durasi :] 0]
				if {$drs > "15"} {
					puthelp "PRIVMSG $chan :\002ERROR\002: File is larger than maximal size. (You only can download under\002 16Mb\002)"
					file delete [glob $path/eggdrop/b.txt]
					return 0
				}
			}
		} else {
			set judulbaru [string map {" " "_" "ð" "" "" "" "" "" "µ" "" {‘} "" { } "_" {`} "" {’} "" {%} "persen" {[} "(" {]} ")" {|_} "" {|} "-" {/_} "-" {"_} "" {#} "" "é" "e"} $data]
			set judulbaru [timpakarakter $judulbaru]
			set judul "$judulbaru.mp3"
		}
	}
	close $yc
	file delete [glob $path/eggdrop/b.txt]
	if {$judul == $ceklink} {
		putquick "PRIVMSG $chan :$reklink"
		return 0
	}
	putquick "PRIVMSG $chan :Processing..."
	catch [list exec vaksin --geo-bypass --no-cache-dir --prefer-ffmpeg --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "ytsearch1:$text"] mptigaruncmd
	if {[regexp {^ERROR*} $mptigaruncmd == 1]} {
		puthelp "PRIVMSG $chan :$mptigaruncmd"
		return 0
	}
	set besar [fixform [file size "$path/public_html/$judulbaru.mp3"]]
	puthelp "PRIVMSG $chan :Download Link: $linkdl$judulbaru.mp3 \[Size: \002$besar\002\] \[Duration: \002$durasi minutes\002\] | (Will be deleted in\002 30 minutes\002)"
	set reklink "Download Link: $linkdl$judulbaru.mp3 \[Size: \002$besar\002\] \[Duration: \002$durasi minutes\002\]"
	set ceklink "$judulbaru.mp3"
	timer 25 { set ceklink "" }
	timer 30 [list hapus $chan $judulbaru]
}

proc mptigalink { nick host hand chan text } {
	global path linkdl hapus ceklink reklink owner judul judulbaru
	catch [list exec vaksin --no-playlist -e --get-duration "$text" > b.txt] mptigareplayitt
	if {[regexp {^ERROR*} $mptigareplayitt == 1]} {
		puthelp "PRIVMSG $chan :$mptigareplayitt"
		file delete [glob $path/eggdrop/b.txt]
		return 0
	}
	set yc [open "b.txt" r]
	while {[gets $yc data] != -1} {
		set data [string map {{"} "" {/} ""} $data]
		if {[string match {[0-9]*} [lindex $data 0]]} {
			set durasi $data
			if {$durasi == "0" && ![string match -nocase {[A-Z]} $durasi]} {
				puthelp "PRIVMSG $chan :\002ERROR\002: Streaming is not allowed."
				file delete [glob $path/eggdrop/b.txt]
				return 0
			}
			if {![matchattr $nick n]} {
				if {[string match "*:*:*" [string tolower $durasi]]} {
					puthelp "PRIVMSG $chan :\002ERROR\002: File is larger than maximal size. (You only can download under\002 16Mb\002)"
					file delete [glob $path/eggdrop/b.txt]
					return 0
				}
				set drs [lindex [split $durasi :] 0]
				if {$drs > "15"} {
					puthelp "PRIVMSG $chan :\002ERROR\002: File is larger than maximal size. (You only can download under\002 16Mb\002)"
					file delete [glob $path/eggdrop/b.txt]
					return 0
				}
			}
		} else {
			set judulbaru [string map {" " "_" "ð" "" "" "" "" "" "µ" "" {‘} "" { } "_" {`} "" {’} "" {%} "persen" {[} "(" {]} ")" {|_} "" {|} "-" {/_} "-" {"_} "" {#} "" "é" "e"} $data]
			set judulbaru [timpakarakter $judulbaru]
			set judul "$judulbaru.mp3"
		}
	}
	close $yc
	file delete [glob $path/eggdrop/b.txt]
	if {$judul == $ceklink} {
		putquick "PRIVMSG $chan :$reklink"
		return 0
	}
	putquick "PRIVMSG $chan :Processing..."
	catch [list exec vaksin --geo-bypass --no-cache-dir --prefer-ffmpeg --no-playlist --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" $text] mptigaruncmdd
	if {[regexp {^ERROR*} $mptigaruncmdd == 1]} {
		puthelp "PRIVMSG $chan :$mptigaruncmdd"
		return 0
	}
	set besar [fixform [file size "$path/public_html/$judulbaru.mp3"]]
	puthelp "PRIVMSG $chan :Download Link: $linkdl$judulbaru.mp3 \[Size: \002$besar\002\] \[Duration: \002$durasi minutes\002\] | (Will be deleted in\002 30 minutes\002)"
	set reklink "Download Link: $linkdl$judulbaru.mp3 \[Size: \002$besar\002\] \[Duration: \002$durasi minutes\002\]"
	set ceklink "$judulbaru.mp3"
	timer 25 { set ceklink "" }
	timer 30 [list hapus $chan $judulbaru]
}

## Mp4 ##
proc mpempat { nick host hand chan text } {
	global botnick troll dlchan author
	if {![string match *[decrypt 64 "eXjyh.jVjlb.EoJZq.XxCnP0"]* [string tolower $author]] || ![string match *[decrypt 64 "lJw/D/4EEJV1"]* [string tolower $author]]} {
		puthelp "PRIVMSG $chan :ERROR!!!"
		return 0
	}
	if {![channel get $chan mp3]} {
		if {[matchattr $nick n]} {
			puthelp "PRIVMSG $chan :- DEACTIVE -" ; return 0
		} else {
			puthelp "PRIVMSG $chan :Please join \002$dlchan\002 for download." ; return 0
		}
	}
	if {[lindex $text 0] == ""} { puthelp "PRIVMSG $chan :Type \002mp3 help\002 for help." ; return 0 }
	if {[string length $text] < 3} { puthelp "PRIVMSG $chan :Maximum 3 characters for download." ; return 0 }
	if {[string match "*stream*" [string tolower $text]]} { puthelp "PRIVMSG $chan :Download\002 Streaming \002is not allowed." ; return 0 }
	if {$nick != "Vaksin" || $nick != "GauL"} {
		if {[string match "*playlist?list*" [string tolower $text]]} { puthelp "PRIVMSG $chan :Download\002 Playlist \002is not allowed." ; return 0 }
	}

	if {[info exists troll(lasttime,$chan,$nick)] && [expr $troll(lasttime,$chan,$nick) + $troll(delay)] > [clock seconds]} {
		putserv "PRIVMSG $chan :Wait\002 [expr $troll(delay) - [expr [clock seconds] - $troll(lasttime,$chan,$nick)]] \002seconds for next download."
		return 0
	}
	set troll(lasttime,$chan,$nick) [clock seconds]
	
	if {![string match "*http*" [lindex $text 0]]} {
		mpempattext $nick $host $hand $chan $text
	} else {
		mpempatlink $nick $host $hand $chan $text
	}
}

proc mpempattext { nick host hand chan text } {
	global path linkdl hapus ceklink reklink owner judul judulbaru
	catch [list exec vaksin -e --get-duration "ytsearch1:$text" > b.txt] mpempatreplayit
	if {[regexp {^ERROR*} $mpempatreplayit == 1]} {
		puthelp "PRIVMSG $chan :$mpempatreplayit"
		file delete [glob $path/eggdrop/b.txt]
		return 0
	}
	set yc [open "b.txt" r]
	while {[gets $yc data] != -1} {
		if {[string match "*ERROR:*" [string tolower $data]]} {
			puthelp "PRIVMSG $chan :$data"
			return 0
		}
		set data [string map {{"} "" {/} ""} $data]
		if {[string match {[0-9]*} [lindex $data 0]]} {
			set durasi $data
			if {$durasi == "0" && ![string match -nocase {[A-Z]} $durasi]} {
				puthelp "PRIVMSG $chan :\002ERROR\002: Streaming is not allowed."
				file delete [glob $path/eggdrop/b.txt]
				return 0
			}
			if {![matchattr $nick n]} {
				if {[string match "*:*:*" [string tolower $durasi]]} {
					puthelp "PRIVMSG $chan :\002ERROR\002: File is larger than maximal size. (You only can download under\002 21Mb\002)"
					file delete [glob $path/eggdrop/b.txt]
					return 0
				}
				set drs [lindex [split $durasi :] 0]
				if {$drs > "20"} {
					puthelp "PRIVMSG $chan :\002ERROR\002: File is larger than maximal size. (You only can download under\002 21Mb\002)"
					file delete [glob $path/eggdrop/b.txt]
					return 0
				}
			}
		} else {
			set judulbaru [string map {" " "_" "ð" "" "" "" "" "" "µ" "" {‘} "" { } "_" {`} "" {’} "" {%} "persen" {[} "(" {]} ")" {|_} "" {|} "-" {/_} "-" {"_} "" {#} "" "é" "e"} $data]
			set judulbaru [timpakarakter $judulbaru]
			set judul "$judulbaru.mp4"
		}
	}
	close $yc
	file delete [glob $path/eggdrop/b.txt]
	if {$judul == $ceklink} {
		putquick "PRIVMSG $chan :$reklink"
		return 0
	}
	putquick "PRIVMSG $chan :Processing..."
	catch [list exec vaksin --geo-bypass --no-cache-dir --prefer-ffmpeg --no-warnings --youtube-skip-dash-manifest -f mp4 -o "$path/public_html/$judulbaru.%(ext)s" ytsearch1:$text] mpempatruncmd
	if {[regexp {^ERROR*} $mpempatruncmd == 1]} {
		puthelp "PRIVMSG $chan :$mpempatruncmd"
		return 0
	}
	set besar [fixform [file size "$path/public_html/$judulbaru.mp4"]]
	puthelp "PRIVMSG $chan :Download Link: $linkdl$judulbaru.mp4 \[Size: \002$besar\002\] \[Duration: \002$durasi minutes\002\] | (Will be deleted in\002 60 minutes\002)"
	set reklink "Download Link: $linkdl$judulbaru.mp4 \[Size: \002$besar\002\] \[Duration: \002$durasi minutes\002\]"
	set ceklink "$judulbaru.mp4"
	timer 25 { set ceklink "" }
	timer 60 [list hapus $chan $judulbaru]
}

proc mpempatlink { nick host hand chan text } {
	global path linkdl hapus ceklink reklink owner judul judulbaru
	catch [list exec vaksin --no-playlist -e --get-duration "$text" > b.txt] mpempatreplayitt
	if {[regexp {^ERROR*} $mpempatreplayitt == 1]} {
		puthelp "PRIVMSG $chan :$mpempatreplayitt"
		file delete [glob $path/eggdrop/b.txt]
		return 0
	}
	set yc [open "b.txt" r]
	while {[gets $yc data] != -1} {
		set data [string map {{"} "" {/} ""} $data]
		if {[string match {[0-9]*} [lindex $data 0]]} {
			set durasi $data
			if {$durasi == "0" && ![string match -nocase {[A-Z]} $durasi]} {
				puthelp "PRIVMSG $chan :\002ERROR\002: Streaming is not allowed."
				file delete [glob $path/eggdrop/b.txt]
				return 0
			}
			if {![matchattr $nick n]} {
				if {[string match "*:*:*" [string tolower $durasi]]} {
					puthelp "PRIVMSG $chan :\002ERROR\002: File is larger than maximal size. (You only can download under\002 21Mb\002)"
					file delete [glob $path/eggdrop/b.txt]
					return 0
				}
				set drs [lindex [split $durasi :] 0]
				if {$drs > "20"} {
					puthelp "PRIVMSG $chan :\002ERROR\002: File is larger than maximal size. (You only can download under\002 21Mb\002)"
					file delete [glob $path/eggdrop/b.txt]
					return 0
				}
			}
		} else {
			set judulbaru [string map {" " "_" "ð" "" "" "" "" "" "µ" "" {‘} "" { } "_" {`} "" {’} "" {%} "persen" {[} "(" {]} ")" {|_} "" {|} "-" {/_} "-" {"_} "" {#} "" "é" "e"} $data]
			set judulbaru [timpakarakter $judulbaru]
			set judul "$judulbaru.mp4"
		}
	}
	close $yc
	file delete [glob $path/eggdrop/b.txt]
	if {$judul == $ceklink} {
		putquick "PRIVMSG $chan :$reklink"
		return 0
	}
	putquick "PRIVMSG $chan :Processing..."
	catch [list exec vaksin --geo-bypass --no-cache-dir --prefer-ffmpeg --no-playlist --no-warnings --youtube-skip-dash-manifest -f mp4 -o "$path/public_html/$judulbaru.%(ext)s" $text] mpempatruncmdd
	if {[regexp {^ERROR*} $mpempatruncmdd == 1]} {
		puthelp "PRIVMSG $chan :$mpempatruncmdd"
		return 0
	}
	set besar [fixform [file size "$path/public_html/$judulbaru.mp4"]]
	puthelp "PRIVMSG $chan :Download Link: $linkdl$judulbaru.mp4 \[Size: \002$besar\002\] \[Duration: \002$durasi minutes\002\] | (Will be deleted in\002 60 minutes\002)"
	set reklink "Download Link: $linkdl$judulbaru.mp4 \[Size: \002$besar\002\] \[Duration: \002$durasi minutes\002\]"
	set ceklink "$judulbaru.mp4"
	timer 25 { set ceklink "" }
	timer 60 [list hapus $chan $judulbaru]
}

## Help ##
proc daftar_help {nick host hand chan text} {
	global botnick
	if {[lindex $text 0] != $botnick} { return 0 }
	if {![matchattr $nick n]} {
		puthelp "PRIVMSG $nick :Mp3 Commands:"
		puthelp "PRIVMSG $nick :\002.mp3 <title + singer>\002 | Example: .mp3 stoney - lobo"
		puthelp "PRIVMSG $nick :\002.mp3 <link>\002 | Example: .mp3 https://www.youtube.com/watch?v=2y-aB3VAaB8"
		puthelp "PRIVMSG $nick :Mp4 Commands:"
		puthelp "PRIVMSG $nick :\002.mp4 <title>\002 | Example: .mp4 cinderella"
		puthelp "PRIVMSG $nick :\002.mp4 <link>\002 | Example: .mp3 https://www.youtube.com/watch?v=2y-aB3VAaB8"
		puthelp "PRIVMSG $nick :-"
	} else {
		puthelp "PRIVMSG $nick :Mp3 Commands:"
		puthelp "PRIVMSG $nick :\002.mp3 <title + singer>\002 | Example: .mp3 stoney - lobo"
		puthelp "PRIVMSG $nick :\002.mp3 <link>\002 | Example: .mp3 https://www.youtube.com/watch?v=2y-aB3VAaB8"
		puthelp "PRIVMSG $nick :Mp4 Commands:"
		puthelp "PRIVMSG $nick :\002.mp4 <title>\002 | Example: .mp4 cinderella"
		puthelp "PRIVMSG $nick :\002.mp4 <link>\002 | Example: .mp3 https://www.youtube.com/watch?v=2y-aB3VAaB8"
		puthelp "PRIVMSG $nick :-"
		puthelp "PRIVMSG $nick :Owner Commands:"
		puthelp "PRIVMSG $nick :Channel:"
		puthelp "PRIVMSG $nick :\002<botnick> on\002 | Active the bot."
		puthelp "PRIVMSG $nick :\002<botnick> off\002 | Deactive the bot."
		puthelp "PRIVMSG $nick :\002<botnick> clear\002 | Delete file."
		puthelp "PRIVMSG $nick :\002<botnick> update\002 | Update youtube-dl version."
		puthelp "PRIVMSG $nick :\002<botnick> file list\002 | File list."
		puthelp "PRIVMSG $nick :Privmsg:"
		puthelp "PRIVMSG $nick :\002+block <nick>\002 | Block user."
		puthelp "PRIVMSG $nick :\002-block <hostname>\002 | Unblock user."
		puthelp "PRIVMSG $nick :\002blocklist\002 | Ignore list."
		puthelp "PRIVMSG $nick :-"
	}
}

## Delete File ##
proc delete_file {nick host hand chan text} {
	global botnick path
	if {![matchattr $nick n]} { puthelp "NOTICE $nick :Akses Ditolak" }
	if {[lindex $text 0] != $botnick} { return 0 }
	set cekisi [glob -nocomplain [file join $path/public_html/ *]]
	if {[llength $cekisi] != 0} {
		eval file delete -force [glob $path/public_html/*]
		puthelp "PRIVMSG $chan :All files has been deleted."
	} else {
		puthelp "PRIVMSG $chan :Folder is empty."
	}
}

## Auto Delete File ##
proc apus {chan judulbaru} {
	global path
	if {[file exists $path/public_html/$judulbaru.mp4] == 1} {
		file delete [glob $path/public_html/$judulbaru.mp4]
		puthelp "PRIVMSG $chan :File\002 $judulbaru.mp4 \002deleted."
	}
}
proc hapus {chan judulbaru} {
	global path
	if {[file exists $path/public_html/$judulbaru.mp3] == 1} {
		file delete [glob $path/public_html/$judulbaru.mp3]
		puthelp "PRIVMSG $chan :File\002 $judulbaru.mp3 \002deleted."
	}
}

## PUB ON/OFF ##
proc pub_on {nick uhost hand chan arg} {
	global botnick
	if {[lindex $arg 0] != $botnick} { return 0 }
	if {![matchattr $nick n]} {
		putquick "NOTICE $nick :Access Denied!!!"
		return 0
	}
	if {[channel get $chan mp3]} {
		puthelp "NOTICE $nick :Already activated"
		return 0
	}
	channel set $chan +mp3
	putquick "PRIVMSG $chan :Mp3 downloader is now \002ACTIVATED\002. Type\002 $botnick help \002for commands list."
}
proc pub_off {nick uhost hand chan arg} {
	global botnick
	if {[lindex $arg 0] != $botnick} { return 0 }
	if {![matchattr $nick n]} {
		putquick "NOTICE $nick :Access Denied!!!"
		return 0
	}
	if {![channel get $chan mp3]} {
		puthelp "NOTICE $nick :Already Deactivated"
		return 0
	}
	channel set $chan -mp3
	putquick "PRIVMSG $chan :- DEACTIVE -"
}

## File List ##
proc pub_filelist {nick host hand chan text} {
	global botnick path
	if {[lindex $text 0] != $botnick} { return 0 }
	if {![matchattr $nick n]} {
		putquick "NOTICE $nick :Access Denied!!!"
		return 0
	}
	set isinya [glob -nocomplain -tail -path $path/public_html/ *]
	if {[llength $isinya] == 0} {
		puthelp "NOTICE $nick :Folder is empty."
		return 0
	}
	puthelp "NOTICE $nick :\002-Songs List-\002"
	foreach f $isinya {
		puthelp "NOTICE $nick :$f"
	}
	puthelp "NOTICE $nick :\002-Finish-\002"
}

## Update youtube-dl Version ##
proc pub_update {nick host hand chan arg} {
	global botnick
	if {[lindex $arg 0] != $botnick} { return 0 }
	if {![matchattr $nick n]} {
		putquick "NOTICE $nick :Access Denied!!!"
		return 0
	}
	catch [list exec vaksin -U] updated
	if {[string match "*up-to-date*" $updated]} {
		catch [list exec vaksin --version] versi
		putquick "PRIVMSG $chan :Your version is Up To Date (\002$versi\002)"
		return 0
	}
	if {[string match -nocase "*ERROR*" $updated]} {
		set errorf [open "a.txt" a+]
		puts $errorf $updated
		close $errorf
		set orf [open "a.txt" r]
		while { [gets $orf line] >= 0 } {
			if {[string match "*ERROR: *" $line]} {
				puthelp "PRIVMSG $chan :$line"
				file delete [glob a.txt]
			}
		}
		close $orf
		return 0
	}
	set update [lindex $updated 3 end]
	putquick "PRIVMSG $chan :New version is available, starting upgrade to $update"
	putquick "PRIVMSG $chan :Done"
}

## Block/Unblock Pub ##
proc msg_blok {nick host hand rest} {
	global botnick owner
	if {![matchattr $nick n]} { puthlp "NOTICE $nick :Access Denied!!!" ; return 0 }
	if {$rest == ""} { puthlp "NOTICE $nick :Syntax: \002+ignore <nick>\002" ; return 0 }
	if {$rest == "*!*@*"} { puthlp "NOTICE $nick :Ilegal hostmask." ; return 0 }
	if {[getchanhost $rest] == ""} { puthlp "NOTICE $nick :\002FAILED:\002 Nick not found, use\002 +block <hostname>\002" ; return 0 }
	if {[isignore [getchanhost $rest]]} { puthlp "NOTICE $nick :\002$rest\002 already blocked." ; return 0 }
	set hostnya "*![getchanhost $rest]"
	newignore $hostnya $nick "*" 0
	puthlp "NOTICE $nick :Blocking... \002$rest\002"
}

proc msg_unblok {nick host hand rest} {
	global botnick
	if {![matchattr $nick n]} { puthlp "NOTICE $nick :Access Denied!!!" ; return 0 }
	if {$rest == ""} { puthlp "NOTICE $nick :Syntax: \002-block <nick>\002" ; return 0 }
	if {[getchanhost $rest] == ""} { puthlp "NOTICE $nick :\002FAILED!!!\002 Syntax: -block <hostname>" ; return 0 }
	set hostnya "*![getchanhost $rest]"
	if {![isignore $hostnya]} { puthlp "NOTICE $nick :\002$rest\002 is not blocked." ; return 0 }
	if {[isignore $hostnya]} {
		killignore $hostnya
		puthlp "NOTICE $nick :Unblocking... \002$rest\002"
		saveuser
	}
}

## Block List ##
proc daftar_ignore {nick host hand rest} {
	global botnick owner
	if {![matchattr $nick n]} { puthlp "NOTICE $nick :Access Denied!!!" ; return 0 }
	if {[ignorelist]==""} {
		puthelp "NOTICE $nick :Block list is empty."
		return 0
	}
	puthelp "NOTICE $nick :\002-Block List-\002"
	foreach x [ignorelist] {
		puthelp "NOTICE $nick :$x"
	}
	puthelp "NOTICE $nick :\002-Finish-\002"
}

proc timpakarakter {judulbaru} {
	set judulbaru [regsub -all {[\u2022]} $judulbaru ""]
	set judulbaru [regsub -all {[\u2714]} $judulbaru ""]
}

proc fixform n {
	if {wide($n) < 1000} {return $n}
	foreach unit {KB MB GB TB P E} {
		set n [expr {$n/1024.}]
		if {$n < 1000} {
			set n [string range $n 0 3]
			regexp {(.+)\.$} $n -> n
			set size "$n $unit"
			return $size
		}
	}
	return Inf
}
set author [decrypt 64 "5qIUj.M1Ufm.RV0zE.rG4xn/K2b4z.w4QJK0 "]
