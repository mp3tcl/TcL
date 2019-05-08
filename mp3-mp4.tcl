#######################################################
#
#									Mp3 and Mp4 Downloader
#												Version 1.6
#
# Author: Vaksin
# Copyright © 2016 All Rights Reserved.
#######################################################
#
# ############
# REQUIREMENTS
# ############
#  "youtube-dl" and "ffmpeg" package installed.
#
# ##########
# CHANGELOG
# ##########
# 1.0
# -First release.
# 1.1
# -Error message now with full reply.
# -Fixed some bugs.
# 1.2
# -Modified commands. Now you can use <botnick command> (Example: "mp3 help").
# -Fixed bug.
# 1.3
# -Fixed Unicode characters bug. (Can't be Download from PC browser).
# 1.4
# -Added youtube-dl update commands.
# -Added code for block streaming.
# -Fixed bugs.
# 1.5
# -Added more Unicode characters that can't be Download from PC.
# -Check file exist or not in folder before Download it.
# 1.6
# -Recoded some code.
# -Added clear file(s) command.
# -Added more Unicode characters that can't be Download from PC.
# -Added mp3-mp4 download size limit (Default is mp3 = 20m, mp4 = 50m).
# -Added to allow/block for download playlist (Default is aloowed).
# -Added more Unicode characters that can't be Download from PC.
# -Fixed bugs.
#
#  (Type "<botnick> help" in channel for command list).

# ########
# CONTACT
# ########
#  If you have any suggestions, comments, questions or report bugs,
#  you can find me on IRC @ForumCerdas Network.
#
#  /server irc.forumcerdas.net:6667   Nick: vaksin
#
######################################################

######################################################
### Settings ###
######################################################

# This is link for download the mp3 or mp4 file.
set linkdl "http://mp3.rhe.name/~mp3/"

# Your public_html folder patch
set path "/home/mp3"

# Set Your Youtube API Key
set key "AIzaSyBlnL8h7FnukIEj9_QLtunU6x2AIO0H9vQ"

# Mp3 and Mp4 Size Limit for download. (Set it blank for free size)
# Example: set mptigasize ""
if {![info exist mptigasize]} { set mptigasize "20m" }
if {![info exist mpempatsize]} { set mpempatsize "50m" }

# Allow Playlist download or not.
# 0 = Allowed, 1 = Not allowed.
if {![info exist allowplaylist]} { set allowplaylist "1" }

###############################################################################
### End of Settings ###
###############################################################################
setudef flag ytconvert
if {![info exist linktotal]} { set linktotal "" }
###############################################################################
#
#      DON'T CHANGE ANYTHING BELOW EVEN YOU KNOW TCL.
#
###############################################################################
package require http
package require json
package require tls
tls::init -tls1 true -ssl2 false -ssl3 false
http::register https 443 tls::socket
::http::config -useragent "Mozilla/5.0 (X11; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0"

bind pub - .mp3 mptiga
bind pub - .mp4 mpempat
bind pub - .cari searchlagu
bind pubm - * carilaguinfo
bind pub n .size ganti_size
bind pub n +playlist playlist:on
bind pub n -playlist playlist:off
bind pub n .playlist playlist:list
bind pubm n "* clear file" delete_file
bind pubm n "* update" pub_update
bind pubm - "* help" daftar_help

## Mp3 ##
proc mptiga { nick host hand chan text } {
	global allowplaylist
	if {![channel get $chan ytconvert]} { return 0 }
	if {[lindex $text 0] == ""} { puthelp "PRIVMSG $chan :Type \002mp3 help\002 for command list." ; return 0 }
	if {[string length $text] < 3} { puthelp "PRIVMSG $chan :Maximum 3 characters for Download." ; return 0 }
	if {[string match "*stream*" [string tolower $text]]} { puthelp "PRIVMSG $chan :Streaming is not allowed." ; return 0 }
	if {$allowplaylist == 1} {
		if {[string match "*playlist?list*" [string tolower $text]]} { puthelp "PRIVMSG $chan :Playlist is not allowed." ; return 0 }
	}
	if {![string match "*http*" [lindex $text 0]]} {
		mptigatext $nick $host $hand $chan $text
	} else {
		mptigalink $nick $host $hand $chan $text
	}
}

proc mptigatext { nick host hand chan text } {
	global path linkdl judulbaru yturl mptigasize
	catch {exec youtube-dl --no-warnings -e --get-duration --get-id "ytsearch1:$text"} mptigareplaytext
	foreach {judul id durasi} [split $mptigareplaytext "\n"] {
		if {[string match "ERROR:*" $judul] || [string match "WARNING:*" $judul]} { puthelp "PRIVMSG $channel :Unable to complete request. Reason: $judul" ; return 0 }
		if {[string match "ERROR:*" $id] || [string match "WARNING:*" $id] || ($id == "")} { puthelp "PRIVMSG $channel :Unable to complete request. Reason: $id" ; return 0 }
		if {[string match "ERROR:*" $durasi]} { puthelp "PRIVMSG $channel :Unable to complete request. Reason: $durasi" ; return 0 }
		if {$durasi == "0"} { puthelp "PRIVMSG $chan :Streaming is not allowed." ; return 0 }
		if {[string match "WARNING:*" $durasi] || $durasi == ""} {
			set durasi "unknown"
		} elseif {![string match "*:*" $durasi] && ![string match "*WARNING*" $durasi] && $durasi != ""} {
			set durasi "$durasi second"
		} else {
			set durasi "$durasi minutes"
		}
		set yturl "https://youtu.be/$id"
	}
	putquick "PRIVMSG $chan :Trying to convert \002$judul\002 please wait..."
	if {$mptigasize != ""} {
		if {![matchattr $nick n]} {
			catch {exec youtube-dl --max-filesize $mptigasize --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/%(title)s.%(ext)s" $yturl} mptigaruncmd
		} else {
			catch {exec youtube-dl --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/%(title)s.%(ext)s" $yturl} mptigaruncmd
		}
	} else {
		catch {exec youtube-dl --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/%(title)s.%(ext)s" $yturl} mptigaruncmd
	}
	foreach line [split $mptigaruncmd "\n"] { 
		if {[string match "ERROR:*" $line]} {
			if {[string match "*unable to download video data*" $line]} { puthelp "PRIVMSG $chan :Unable to download data at this time. (\002Try again\002)" ; return 0 }
			puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: $line" ; return 0
		}
		if {[string match "*File is larger than max-filesize*" $line]} { puthelp "PRIVMSG $chan :File is larger than\002 $mptigasize\002. (Only owner can Download big file)" ; return 0 }
		if {[string match "*.mp3*" $line]} {
			set line [lindex [split $line] end]
			regsub {/home/mp3/public_html/} $line {} line ; regsub { } $line {} jdmp3
		}
	}
	if {[file exists $path/public_html/$jdmp3] == 1} {
		set besar [fixform [file size "$path/public_html/$jdmp3"]]
		putquick "PRIVMSG $chan :Download Link: $linkdl$jdmp3 \[Size: \002$besar\002\] \[Duration: \002$durasi\002\] | (Will be deleted in\002 30 minutes\002)"
		timer 30 [list apusmp3 $chan $jdmp3]
	} else {
		puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: An unexpected error."
	}
}

proc mptigalink { nick host hand chan text } {
	global path linkdl judulbaru durasi id judul mptigasize
	catch {exec youtube-dl --no-warnings -e --get-duration "$text"} mptigareplaylink
	foreach {judul durasi} [split $mptigareplaylink "\n"] {
		if {[string match "ERROR:*" $judul] || [string match "WARNING:*" $judul]} { puthelp "PRIVMSG $channel :Unable to complete request. Reason: $judul" ; return 0 }
		if {[string match "ERROR:*" $durasi]} { puthelp "PRIVMSG $channel :Unable to complete request. Reason: $durasi" ; return 0 }
		if {$durasi == "0"} { puthelp "PRIVMSG $channel :Streaming is not allowed." ; return 0 }
		if {[string match "WARNING:*" $durasi] || $durasi == ""} {
			set durasi "unknown"
		} elseif {![string match "*:*" $durasi] && ![string match "*WARNING*" $durasi] && $durasi != ""} {
			set durasi "$durasi second"
		} else {
			set durasi "$durasi minutes"
		}
	}
	putquick "PRIVMSG $chan :Trying to convert \002$judul\002 please wait..."
	if {$mptigasize != ""} {
		if {![matchattr $nick n]} {
			catch {exec youtube-dl --max-filesize $mptigasize --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/%(title)s.%(ext)s" $text} mptigaruncmdd
		} else {
			catch {exec youtube-dl --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/%(title)s.%(ext)s" $text} mptigaruncmdd
		}
	} else {
		catch {exec youtube-dl --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/%(title)s.%(ext)s" $text} mptigaruncmdd
	}
	foreach line [split $mptigaruncmdd "\n"] {
		if {[string match "ERROR:*" $line]} {
			if {[string match "*unable to download video data*" $line]} { puthelp "PRIVMSG $chan :Unable to download data at this time. (\002Try again\002)" ; return 0 }
			puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: $line" ; return 0
		}
		if {[string match "*File is larger than max-filesize*" $line]} { puthelp "PRIVMSG $chan :File is larger than\002 $mptigasize\002. (Only owner can Download big file)" ; return 0 }
		if {[string match "*.mp3*" $line]} {
			set line [lindex [split $line] end]
			regsub {/home/mp3/public_html/} $line {} line ; regsub { } $line {} jdmp3
		}
	}
	if {[file exists $path/public_html/$jdmp3] == 1} {
		set besar [fixform [file size "$path/public_html/$jdmp3"]]
		putquick "PRIVMSG $chan :Download Link: $linkdl$jdmp3 \[Size: \002$besar\002\] \[Duration: \002$durasi\002\] | (Will be deleted in\002 30 minutes\002)"
		timer 30 [list apusmp3 $chan $jdmp3]
	} else {
		puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: An unexpected error."
	}
}

## Mp4 ##
proc mpempat { nick host hand chan text } {
	global allowplaylist
	if {![channel get $chan ytconvert]} { return 0 }
	if {[lindex $text 0] == ""} { puthelp "PRIVMSG $chan :Type \002mp3 help\002 for command list." ; return 0 }
	if {[string length $text] < 3} { puthelp "PRIVMSG $chan :Maximum 3 characters for Download." ; return 0 }
	if {[string match "*stream*" [string tolower $text]]} { putquick "PRIVMSG $chan :Streaming is not allowed." ; return 0 }
	if {$allowplaylist == 1} {
		if {[string match "*playlist?list*" [string tolower $text]]} { puthelp "PRIVMSG $chan :Playlist is not allowed." ; return 0 }
	}
	if {[string match "*porn*" [string tolower $text]] || [string match "*xxx*" [string tolower $text]] || [string match "*xvideos*" [string tolower $text]]} {
		if {![matchattr $nick n]} { puthelp "PRIVMSG $chan :Porn is not allowed.\002" ; return 0 }
	}
	if {![string match "*http*" [lindex $text 0]]} {
		mpempattext $nick $host $hand $chan $text
	} else {
		mpempatlink $nick $host $hand $chan $text
	}
}

proc mpempattext { nick host hand chan text } {
	global path linkdl judulbaru durasi id judul yturl mpempatsize
	catch {exec youtube-dl --no-warnings -e --get-duration --get-id "ytsearch1:$text"} mpempatreplaytext
	foreach {judul id durasi} [split $mpempatreplaytext "\n"] {
		if {[string match "ERROR:*" $judul] || [string match "WARNING:*" $judul]} { puthelp "PRIVMSG $channel :Unable to complete request. Reason: $judul" ; return 0 }
		if {[string match "ERROR:*" $id] || [string match "WARNING:*" $id] || ($id == "")} { puthelp "PRIVMSG $channel :Unable to complete request. Reason: $id" ; return 0 }
		if {[string match "ERROR:*" $durasi]} { puthelp "PRIVMSG $channel :Unable to complete request. Reason: $durasi" ; return 0 }
		if {$durasi == "0"} { puthelp "PRIVMSG $chan :Streaming is not allowed." ; return 0 }
		if {[string match "WARNING:*" $durasi] || $durasi == ""} {
			set durasi "unknown"
		} elseif {![string match "*:*" $durasi] && ![string match "*WARNING*" $durasi] && $durasi != ""} {
			set durasi "$durasi second"
		} else {
			set durasi "$durasi minutes"
		}
		set yturl "https://youtu.be/$id"
	}
	putquick "PRIVMSG $chan :Trying to convert \002$judul\002 please wait..."
	if {$mpempatsize != ""} {
		if {![matchattr $nick n]} {
			catch {exec youtube-dl --max-filesize $mpempatsize --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -f mp4 -o "$path/public_html/%(title)s.%(ext)s" $yturl} mpempatruncmd
		} else {
			catch {exec youtube-dl --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -f mp4 -o "$path/public_html/%(title)s.%(ext)s" $yturl} mpempatruncmd
		}
	} else {
		catch {exec youtube-dl --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -f mp4 -o "$path/public_html/%(title)s.%(ext)s" $yturl} mpempatruncmd
	}
	foreach line [split $mpempatruncmd "\n"] {
		if {[string match "ERROR:*" $line]} {
			if {[string match "*unable to download video data*" $line]} { puthelp "PRIVMSG $chan :Unable to download data at this time. (\002Try again\002)" ; return 0 }
			puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: $line" ; return 0
		}
		if {[string match "*File is larger than max-filesize*" $line]} { puthelp "PRIVMSG $chan :File is larger than\002 $mpempatsize\002. (Only owner can Download big file)" ; return 0 }
		if {[string match "*.mp4*" $line] && ![string match "*has already been downloaded*" $line]} {
			set line [lindex [split $line] end]
			regsub {/home/mp3/public_html/} $line {} line ; regsub { } $line {} jdmp4
		}
		if {[string match "*has already been downloaded*" $line]} {
			set line [lindex [split $line] 1]
			regsub {/home/mp3/public_html/} $line {} jdmp4
		}
	}
	if {[file exists $path/public_html/$jdmp4] == 1} {
		set besar [fixform [file size "$path/public_html/$jdmp4"]]
		putquick "PRIVMSG $chan :Download Link: $linkdl$jdmp4 \[Size: \002$besar\002\] \[Duration: \002$durasi\002\] | (Will be deleted in\002 60 minutes\002)"
		timer 60 [list apusmp4 $chan $jdmp4]
	} else {
		puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: An unexpected error."
	}
}

proc mpempatlink { nick host hand chan text } {
	global path linkdl judulbaru durasi id judul mpempatsize
	catch {exec youtube-dl --no-warnings -e --get-duration "$text"} mpempatreplaylink
	foreach {judul durasi} [split $mpempatreplaylink \n] {
		if {[string match "ERROR:*" $judul] || [string match "WARNING:*" $judul]} { puthelp "PRIVMSG $chan :Unable to complete request. Reason: $judul" ; return 0 }
		if {[string match "ERROR:*" $durasi]} { puthelp "PRIVMSG $chan :Unable to complete request. Reason: $durasi" ; return 0 }
		if {$durasi == "0"} { puthelp "PRIVMSG $chan :Streaming is not allowed." ; return 0 }
		if {[string match "WARNING:*" $durasi] || $durasi == ""} {
			set durasi "unknown"
		} elseif {![string match "*:*" $durasi] && ![string match "*WARNING*" $durasi] && $durasi != ""} {
			set durasi "$durasi second"
		} else {
			set durasi "$durasi minutes"
		}
	}
	putquick "PRIVMSG $chan :Trying to convert \002$judul\002 please wait..."
	if {$mpempatsize != ""} {
		if {![matchattr $nick n]} {
			catch {exec youtube-dl --max-filesize $mpempatsize --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -f mp4 -o "$path/public_html/%(title)s.%(ext)s" $text} mpempatruncmdd
		} else {
			catch {exec youtube-dl --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -f mp4 -o "$path/public_html/%(title)s.%(ext)s" $text} mpempatruncmdd
		}
	} else {
		catch {exec youtube-dl --prefer-ffmpeg --restrict-filenames --ignore-config --no-cache-dir --no-resize-buffer --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -f mp4 -o "$path/public_html/%(title)s.%(ext)s" $text} mpempatruncmdd
	}
	foreach line [split $mpempatruncmdd "\n"] {
		if {[string match "ERROR:*" $line]} {
			if {[string match "*unable to download video data*" $line]} { puthelp "PRIVMSG $chan :Unable to download data at this time. (\002Try again\002)" ; return 0 }
			puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: $line" ; return 0
		}
		if {[string match "*File is larger than max-filesize*" $line]} { puthelp "PRIVMSG $chan :File is larger than\002 $mpempatsize\002. (Only owner can Download big file)" ; return 0 }
		if {[string match "*.mp4*" $line] && ![string match "*has already been downloaded*" $line]} {
			set line [lindex [split $line] end]
			regsub {/home/mp3/public_html/} $line {} line ; regsub { } $line {} jdmp4
		}
		if {[string match "*has already been downloaded*" $line]} {
			set line [lindex [split $line] 1]
			regsub {/home/mp3/public_html/} $line {} jdmp4
		}
	}
	if {[file exists $path/public_html/$jdmp4] == 1} {
		set besar [fixform [file size "$path/public_html/$jdmp4"]]
		putquick "PRIVMSG $chan :Download Link: $linkdl$jdmp4 \[Size: \002$besar\002\] \[Duration: \002$durasi\002\] | (Will be deleted in\002 60 minutes\002)"
		timer 60 [list apusmp4 $chan $jdmp4]
	} else {
		puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: An unexpected error."
	}
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
		puthelp "PRIVMSG $nick :\002.mp4 <link>\002 | Example: .mp4 https://www.youtube.com/watch?v=2y-aB3VAaB8"
		puthelp "PRIVMSG $nick :-"
		puthelp "PRIVMSG $nick :\002.cari <title - singer>\002 | Search song from youtube."
		puthelp "PRIVMSG $nick :- END -"
	} else {
		puthelp "PRIVMSG $nick :Mp3 Commands:"
		puthelp "PRIVMSG $nick :\002.mp3 <title + singer>\002 | Example: .mp3 stoney - lobo"
		puthelp "PRIVMSG $nick :\002.mp3 <link>\002 | Example: .mp3 https://www.youtube.com/watch?v=2y-aB3VAaB8"
		puthelp "PRIVMSG $nick :Mp4 Commands:"
		puthelp "PRIVMSG $nick :\002.mp4 <title>\002 | Example: .mp4 cinderella"
		puthelp "PRIVMSG $nick :\002.mp4 <link>\002 | Example: .mp4 https://www.youtube.com/watch?v=2y-aB3VAaB8"
		puthelp "PRIVMSG $nick :-"
		puthelp "PRIVMSG $nick :\002.cari <song>\002 or \002.cari <result number> <song>\002  | Search song from youtube. (Default result number is 5."
		puthelp "PRIVMSG $nick :\002.size mp3/mp4 <size>\002 | Mp3/mp4 size limit for download. Example: .size mp3 20m"
		puthelp "PRIVMSG $nick :\002.size list\002 | Show the limit size download"
		puthelp "PRIVMSG $nick :\002+playlist\002 | Allow download playlist."
		puthelp "PRIVMSG $nick :\002-playlist\002 | Block download playlist."
		puthelp "PRIVMSG $nick :\002.playlist\002 | Show playlist setting."
		puthelp "PRIVMSG $nick :\002<botnick> clear file\002 | Delete file."
		puthelp "PRIVMSG $nick :\002<botnick> update\002 | Update youtube-dl version."
		puthelp "PRIVMSG $nick :- END -"
	}
}

## Delete File ##
proc delete_file {nick host hand chan text} {
	global botnick path
	if {[lindex $text 0] != $botnick} { return 0 }
	set cekisi [glob -nocomplain [file join $path/public_html/ *]]
	if {[llength $cekisi] <= 1} {
		puthelp "PRIVMSG $chan :Folder is empty."
		return 0
	}
	set biarin "index.html"
	foreach file $cekisi {
		if {![string match "*$biarin*" [string tolower $file]]} {
			eval file delete $file
		}
	}
	puthelp "PRIVMSG $chan :All files has been deleted."
}

## Auto Delete File ##
proc apusmp4 {chan jdmp4} {
	global path
	if {[file exists $path/public_html/$jdmp4] == 1} {
		file delete [glob $path/public_html/$jdmp4]
		puthelp "PRIVMSG $chan :File\002 $jdmp4 \002deleted."
	}
}
proc apusmp3 {chan jdmp3} {
	global path
	if {[file exists $path/public_html/$jdmp3] == 1} {
		file delete [glob $path/public_html/$jdmp3]
		puthelp "PRIVMSG $chan :File\002 $jdmp3 \002deleted."
	}
}

## Update youtube-dl Version ##
proc pub_update {nick host hand chan arg} {
	global botnick
	if {[lindex $arg 0] != $botnick} { return 0 }
	catch {exec youtube-dl -U} updated
	foreach x [split $updated) "\n"] {
		if {[string match "*ERROR: *" $x]} {
			puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: $x" ; return 0
		} elseif {[string match "*up-to-date*" $x]} {
			catch {exec youtube-dl --version} versi
			puthelp "PRIVMSG $chan :Your version is Up To Date. Version: \002$versi\002" ; return 0
		} else {
			set update [lindex $updated 3 end]
			puthelp "PRIVMSG $chan :New version is available, starting upgrade to \002$update\002"
			after 1000
			puthelp "PRIVMSG $chan :Done" ; return 0
		}
	}
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

proc playlist:on {nick host hand chan text} {
	global allowplaylist
	set allowplaylist 1
	puthelp "PRIVMSG $chan :Playlist can't be downloaded now."
}

proc playlist:off {nick host hand chan text} {
	global allowplaylist
	set allowplaylist 0
	puthelp "PRIVMSG $chan :Allow to download Playlist."
}

proc playlist:list {nick host hand chan text} {
	global allowplaylist
	if {$allowplaylist == 0} { puthelp "PRIVMSG $chan :Download Playlist is \002Allowed\002" ; return }
	if {$allowplaylist == 1} { puthelp "PRIVMSG $chan :Download Playlist is \002Not allowed\002" ; return }
}

proc ganti_size {nick host hand chan text} {
	global mptigasize mpempatsize
	if {[lindex $text 0] == ""} {
		puthelp "PRIVMSG $chan :Syntax:\002.size <mp3/mp4> <size>"
		puthelp "PRIVMSG $chan :Syntax:\002.size <off>"
		return 0
	}
	if {[lindex $text 0] == "mp3"} {
		set size [lindex $text 1]
		set mptigasize $size
		puthelp "PRIVMSG $chan :Mp3 download size change to \002$size\002."
	} elseif {[lindex $text 0] == "mp4"} {
		set size [lindex $text 1]
		set mpempatsize $size
		puthelp "PRIVMSG $chan :Mp4 download size change to \002$size\002."
	} elseif {[lindex $text 0] == "off"} {
		set mptigasize ""
		set mpempatsize ""
		puthelp "PRIVMSG $chan :Download size now is \002FREE\002."
	} elseif {[lindex $text 0] == "list"} {
		puthelp "PRIVMSG $chan :Mp3 size limit is \002$mptigasize\002"
		puthelp "PRIVMSG $chan :Mp4 size limit is \002$mpempatsize\002"
	}
}

#########################################################################################
proc carilaguinfo {nick uhost hand chan text} {
	global key
	if {[channel get $chan ytconvert] && [regexp -nocase -- {(?:http(?:s|).{3}|)(?:www.|)(?:youtube.com\/watch\?.*v=|youtu.be\/)([\w-]{11})} $text url id]} {
		if {[string match "*.flac*" [string tolower $text]] || [string match "*.mp3*" [string tolower $text]] || [string match "*.mp4*" [string tolower $text]] || [string match "*.get*" [string tolower $text]] || [string match "*.m4a*" [string tolower $text]] || [string match "*.dl01*" [string tolower $text]]} { return 0 }
		set url "https://www.googleapis.com/youtube/v3/videos?id=$id&key=$key&part=snippet,statistics,contentDetails&fields=items(snippet(title,channelTitle,publishedAt),statistics(viewCount),contentDetails(duration))"
		set ids [getinfocari $url]
		set title [encoding convertfrom [lindex $ids 0 1 3]]
		set pubiso [lindex $ids 0 1 1]
		regsub {\.000Z} $pubiso "" pubiso
		set pubtime [clock format [clock scan $pubiso]]
		set user [encoding convertfrom [lindex $ids 0 1 5]]
		set isotime [lindex $ids 0 3 1]
		regsub -all {PT|S} $isotime "" isotime
		regsub -all {H|M} $isotime ":" isotime
		if { [string index $isotime end-1] == ":" } {
			set sec [string index $isotime end]
			set trim [string range $isotime 0 end-1]
			set isotime ${trim}0$sec
		} elseif { [string index $isotime 0] == "0" } {
			set isotime "stream"
		} elseif { [string index $isotime end-2] != ":" } {
			set isotime "${isotime}s"
		}
		set views [lindex $ids 0 5 1]
		puthelp "PRIVMSG $chan :\[\002Title\002\]: \002$title\002 by $user (duration: $isotime)"
		#puthelp "PRIVMSG $chan :\002\00301,00You\00300,04Tube\003\002 \002$title\002 by $user (duration: $isotime) on $pubtime, $views views"
	}
}

proc getinfocari { url } {
	global linktotal
	if {$linktotal != ""} {
		for { set i 1 } { $i <= $linktotal } { incr i } {
			set rawpage [::http::data [::http::geturl "$url" -timeout 5000]]
			if {[string length rawpage] > 0} { break }
		}
		if {[string length $rawpage] == 0} { error "youtube returned ZERO no data :( or we couldnt connect properly" }
		set ids [dict get [json::json2dict $rawpage] items]
		return $ids
	} else {
		for { set i 1 } { $i <= 5 } { incr i } {
			set rawpage [::http::data [::http::geturl "$url" -timeout 5000]]
			if {[string length rawpage] > 0} { break }
		}
		if {[string length $rawpage] == 0} { error "youtube returned ZERO no data :( or we couldnt connect properly" }
		set ids [dict get [json::json2dict $rawpage] items]
		return $ids
	}
}

proc searchlagu {nick uhost hand chan text} {
	global key linktotal
	if {![channel get $chan ytconvert] } { return }
	if {$text == ""} { puthelp "PRIVMSG $chan :Syntax:\002 .cari <song> \002or\002 .cari <result number> <song> \002(Default result number is 5)" ; return 0 }
	if {[regexp {[0-9]} [lindex $text 0]]} {
		set linktotal [lindex $text 0]
		set text [string range $text 1 end]
	} else {
		set text [string range $text 0 end]
	}
	regsub -all {\s+} $text "%20" text
	set text [string map {{"} {'} {`} {'}} $text]
	
	if {$linktotal != ""} {
		set url "https://www.googleapis.com/youtube/v3/search?part=snippet&fields=items(id(videoId),snippet(title))&maxResults=$linktotal&key=$key&q=$text"
		set ids [getinfocari $url]
		for {set i 0} {$i < $linktotal} {incr i} {
			set id [lindex $ids $i 1 1]
			set desc [encoding convertfrom [lindex $ids $i 3 1]]
			regsub {&#39;} $desc {'} desc
			regsub {amp;} $desc {} desc
			set yout "https://youtu.be/$id"
			set tes "$desc -> $yout"
			foreach line [split $tes "\n"] {
				puthelp "PRIVMSG $nick :$line"
			}
		}
		unset linktotal
	} else {
		set url "https://www.googleapis.com/youtube/v3/search?part=snippet&fields=items(id(videoId),snippet(title))&key=$key&q=$text"
		set ids [getinfocari $url]
		for {set i 0} {$i < 5} {incr i} {
			set id [lindex $ids $i 1 1]
			set desc [encoding convertfrom [lindex $ids $i 3 1]]
			regsub {&#39;} $desc {'} desc
			regsub {amp;} $desc {} desc
			set yout "https://youtu.be/$id"
			set tes "$desc -> $yout"
			foreach line [split $tes "\n"] {
				puthelp "PRIVMSG $nick :$line"
			}
		}
	}
}
