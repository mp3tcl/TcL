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
# -Modified commands. Now you can use <botnick command> (Example: "mp3 help")
# -Fixed bug          							.       																	
# 1.3																																
# -Fixed Unicode characters bug. (Can't be Download from PC browser)																			
# 1.4																																
# -Added youtube-dl update commands.															
# -Added code for block streaming.
# -Fixed bugs																																																												
# 1.5																															
# -Added more Unicode characters that can't be Download from PC.		
# -Check file exist or not in folder before Download it									
# 1.6
# -Recoded some code
# -Added clear cache command
# -Added supported sites list command
# -Added more Unicode characters that can't be Download from PC.
# -Fixed bugs
#																																	
#  (Type "<botnick> help" in channel for command list)								
#																																
# #######																											
# CONTACT																											
# #######																											
#  If you have any suggestions, comments, questions or report bugs,	
#  you can find me on IRC @ForumCerdas Network									
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
::http::config -useragent "Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"

bind pub - .mp3 mptiga
bind pub - .mp4 mpempat
bind pubm n "* clear file" delete_file
bind pubm n "* clear cache" delete_cache
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
	global path linkdl judulbaru durasi id judul yturl mptigasize
	if {[string match "* -*" [string tolower $text]]} { regsub {\-} $text {} text }
	search $nick $host $hand $chan $text
	autoinfo $nick $host $hand $chan $text
	if {$durasi == "stream"} { puthelp "PRIVMSG $chan :Streaming is not allowed." ; return 0 }
	if {[string match "*:*" $durasi]} { set durasi "$durasi minutes" }
	set judulbaru [string map {" " "_" "ÂŽ" "" "ðŸŽ¶" "" "ðŸŽ§" "" "ðŸŽµ" "" "Ÿ" "" "¶" "" "?" "" "ð" "" "µ" "" {¤} {} {?} "" {`} "" {"} "" {} "" {?} "" {%} "persen" {[} "(" {]} ")" {|_} "" {/} "_" {|} "-" {/_} "-" {"_} "" {#} "" "é" "e"} $judul]
	putquick "PRIVMSG $chan :Trying to convert \002$judul\002 please wait..."
	if {$mptigasize != ""} {
		if {![matchattr $nick n]} {
			catch {exec youtube-dl --max-filesize $mptigasize --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$yturl"} mptigaruncmd
		} else {
			catch {exec youtube-dl --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$yturl"} mptigaruncmd
		}
	} else {
		catch {exec youtube-dl --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$yturl"} mptigaruncmd
	}
	foreach line [split $mptigaruncmd "\n"] { 
		if {[string match "ERROR:*" $line]} { puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: $line" ; return 0 }
		if {[string match "*File is larger than max-filesize*" $line]} { puthelp "PRIVMSG $chan :File is larger than\002 $mptigasize\002. (Only owner can Download big file)" ; return 0 }
	}
	if {[file exists $path/public_html/$judulbaru.mp3] == 1} {
		set besar [fixform [file size "$path/public_html/$judulbaru.mp3"]]
		putquick "PRIVMSG $chan :Download Link: $linkdl$judulbaru.mp3 \[Size: \002$besar\002\] \[Duration: \002$durasi\002\] | (Will be deleted in\002 30 minutes\002)"
		timer 30 [list apusmp3 $chan $judulbaru]
	} else {
		puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: An unexpected error."
	}
}

proc mptigalink { nick host hand chan text } {
	global path linkdl judulbaru durasi id judul mptigasize
	if {[regexp -nocase -- {(?:http(?:s|).{3}|)(?:www.|)(?:youtube.com\/watch\?.*v=|youtu.be\/)([\w-]{11})} $text url id]} {
		autoinfo $nick $host $hand $chan $text
		if {$durasi == "stream"} { putquick "PRIVMSG $chan :Streaming is not allowed." ; return 0 }
		if {[string match "*:*" $durasi]} { set durasi "$durasi minutes" }
	} else {
		catch {exec youtube-dl -e --get-duration "$text"} mptigareplaylink
		foreach {judul durasi} [split $mptigareplaylink "\n"] {
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
	}
	set judulbaru [string map {" " "_" "ÂŽ" "" "ðŸŽ¶" "" "ðŸŽ§" "" "ðŸŽµ" "" "Ÿ" "" "¶" "" "?" "" "ð" "" "µ" "" {¤} {} {?} "" {`} "" {"} "" {} "" {?} "" {%} "persen" {[} "(" {]} ")" {|_} "" {/} "_" {|} "-" {/_} "-" {"_} "" {#} "" "é" "e"} $judul]
	putquick "PRIVMSG $chan :Trying to convert \002$judul\002 please wait..."
	if {$mptigasize != ""} {
		if {![matchattr $nick n]} {
			catch {exec youtube-dl --max-filesize $mptigasize --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$text"} mptigaruncmdd
		} else {
			catch {exec youtube-dl --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$text"} mptigaruncmdd
		}
	} else {
		catch {exec youtube-dl --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format mp3 --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$text"} mptigaruncmdd
	}
	foreach line [split $mptigaruncmdd "\n"] {
		if {[string match "ERROR:*" $line]} { puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: $line" ; return 0 }
		if {[string match "*File is larger than max-filesize*" $line]} { puthelp "PRIVMSG $chan :File is larger than\002 $mptigasize\002. (Only owner can Download big file)" ; return 0 }
	}
	if {[file exists $path/public_html/$judulbaru.mp3] == 1} {
		set besar [fixform [file size "$path/public_html/$judulbaru.mp3"]]
		putquick "PRIVMSG $chan :Download Link: $linkdl$judulbaru.mp3 \[Size: \002$besar\002\] \[Duration: \002$durasi\002\] | (Will be deleted in\002 30 minutes\002)"
		timer 30 [list apusmp3 $chan $judulbaru]
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
	if {[string match "* -*" [string tolower $text]]} { regsub {\-} $text {} text }
	search $nick $host $hand $chan $text
	autoinfo $nick $host $hand $chan $text
	if {$durasi == "stream"} { puthelp "PRIVMSG $chan :Streaming is not allowed." ; return 0 }
	if {[string match "*:*" $durasi]} { set durasi "$durasi minutes" }
	set judulbaru [string map {" " "_" "ÂŽ" "" "ðŸŽ¶" "" "ðŸŽ§" "" "ðŸŽµ" "" "Ÿ" "" "¶" "" "?" "" "ð" "" "µ" "" {¤} {} {?} "" {`} "" {"} "" {} "" {?} "" {%} "persen" {[} "(" {]} ")" {|_} "" {/} "_" {|} "-" {/_} "-" {"_} "" {#} "" "é" "e"} $judul]
	putquick "PRIVMSG $chan :Trying to convert \002$judul\002 please wait..."
	if {$mpempatsize != ""} {
		if {![matchattr $nick n]} {
			catch {exec youtube-dl --max-filesize $mpempatsize --prefer-ffmpeg --prefer-ffmpeg --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --youtube-skip-dash-manifest -f mp4 -o "$path/public_html/$judulbaru.%(ext)s" "$yturl"} mpempatruncmd
		} else {
			catch {exec youtube-dl --prefer-ffmpeg --prefer-ffmpeg --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --youtube-skip-dash-manifest -f mp4 -o "$path/public_html/$judulbaru.%(ext)s" "$yturl"} mpempatruncmd
		}
	} else {
		catch {exec youtube-dl --prefer-ffmpeg --prefer-ffmpeg --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --youtube-skip-dash-manifest -f mp4 -o "$path/public_html/$judulbaru.%(ext)s" "$yturl"} mpempatruncmd
	}
	foreach line [split $mpempatruncmd "\n"] {
		if {[string match "ERROR:*" $line]} { puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: $line" ; return 0 }
		if {[string match "*File is larger than max-filesize*" $line]} { puthelp "PRIVMSG $chan :File is larger than\002 $mpempatsize\002. (Only owner can Download big file)" ; return 0 }
	}
	if {[file exists $path/public_html/$judulbaru.mp4] == 1} {
		set besar [fixform [file size "$path/public_html/$judulbaru.mp4"]]
		putquick "PRIVMSG $chan :Download Link: $linkdl$judulbaru.mp4 \[Size: \002$besar\002\] \[Duration: \002$durasi\002\] | (Will be deleted in\002 60 minutes\002)"
		timer 60 [list apusmp4 $chan $judulbaru]
	} else {
		puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: An unexpected error."
	}
}

proc mpempatlink { nick host hand chan text } {
	global path linkdl judulbaru durasi id judul mpempatsize
	if {[regexp -nocase -- {(?:http(?:s|).{3}|)(?:www.|)(?:youtube.com\/watch\?.*v=|youtu.be\/)([\w-]{11})} $text url id]} {
		autoinfo $nick $host $hand $chan $text
		if {$durasi == "stream"} { puthelp "PRIVMSG $chan :Streaming is not allowed." ; return 0 }
		if {[string match "*:*" $durasi]} { set durasi "$durasi minutes" }
	} else {
		catch {exec youtube-dl -e --get-duration "$text"} mpempatreplaylink
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
	}
	set judulbaru [string map {" " "_" "ÂŽ" "" "ðŸŽ¶" "" "ðŸŽ§" "" "ðŸŽµ" "" "Ÿ" "" "¶" "" "?" "" "ð" "" "µ" "" {¤} {} {?} "" {`} "" {"} "" {} "" {?} "" {%} "persen" {[} "(" {]} ")" {|_} "" {/} "_" {|} "-" {/_} "-" {"_} "" {#} "" "é" "e"} $judul]
	putquick "PRIVMSG $chan :Trying to convert \002$judul\002 please wait..."
	if {$mpempatsize != ""} {
		if {![matchattr $nick n]} {
			catch {exec youtube-dl --max-filesize $mpempatsize --prefer-ffmpeg --prefer-ffmpeg --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --youtube-skip-dash-manifest -f mp4 -o "$path/public_html/$judulbaru.%(ext)s" "$text"} mpempatruncmdd
		} else {
			catch {exec youtube-dl --prefer-ffmpeg --prefer-ffmpeg --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --youtube-skip-dash-manifest -f mp4 -o "$path/public_html/$judulbaru.%(ext)s" "$text"} mpempatruncmdd
		}
	} else {
		catch {exec youtube-dl --prefer-ffmpeg --prefer-ffmpeg --no-playlist --no-mtime --abort-on-error --no-color --no-mark-watched --no-call-home --youtube-skip-dash-manifest -f mp4 -o "$path/public_html/$judulbaru.%(ext)s" "$text"} mpempatruncmdd
	}
	foreach line [split $mpempatruncmdd "\n"] {
		if {[string match "ERROR:*" $line]} { puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: $line" ; return 0 }
		if {[string match "*File is larger than max-filesize*" $line]} { puthelp "PRIVMSG $chan :File is larger than\002 $mpempatsize\002. (Only owner can Download big file)" ; return 0 }
	}
	if {[file exists $path/public_html/$judulbaru.mp4] == 1} {
		set besar [fixform [file size "$path/public_html/$judulbaru.mp4"]]
		putquick "PRIVMSG $chan :Download Link: $linkdl$judulbaru.mp4 \[Size: \002$besar\002\] \[Duration: \002$durasi\002\] | (Will be deleted in\002 60 minutes\002)"
		timer 60 [list apusmp4 $chan $judulbaru]
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
		puthelp "PRIVMSG $nick :- END -"
	} else {
		puthelp "PRIVMSG $nick :Mp3 Commands:"
		puthelp "PRIVMSG $nick :\002.mp3 <title + singer>\002 | Example: .mp3 stoney - lobo"
		puthelp "PRIVMSG $nick :\002.mp3 <link>\002 | Example: .mp3 https://www.youtube.com/watch?v=2y-aB3VAaB8"
		puthelp "PRIVMSG $nick :Mp4 Commands:"
		puthelp "PRIVMSG $nick :\002.mp4 <title>\002 | Example: .mp4 cinderella"
		puthelp "PRIVMSG $nick :\002.mp4 <link>\002 | Example: .mp4 https://www.youtube.com/watch?v=2y-aB3VAaB8"
		puthelp "PRIVMSG $nick :-"
		puthelp "PRIVMSG $nick :\002<botnick> clear file\002 | Delete file."
		puthelp "PRIVMSG $nick :\002<botnick> clear cache\002 | Delete cache."
		puthelp "PRIVMSG $nick :\002<botnick> update\002 | Update youtube-dl version."
		puthelp "PRIVMSG $nick :- END -"
	}
}

## Delete Cache ##
proc delete_cache {nick host hand chan text} {
	global botnick path
	if {[lindex $text 0] != $botnick} { return 0 }
	set cekcache [glob -nocomplain [file join $path/.cache/youtube-dl/youtube-sigfuncs/ *]]
	if {[llength $cekcache] != 0} {
		eval file delete -force [glob $path/.cache/youtube-dl/youtube-sigfuncs/*]
		puthelp "PRIVMSG $chan :All cache has been deleted."
	} else {
		puthelp "PRIVMSG $chan :Folder is empty."
	}
}

## Delete File ##
proc delete_file {nick host hand chan text} {
	global botnick path
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
proc apusmp4 {chan judulbaru} {
	global path
	if {[file exists $path/public_html/$judulbaru.mp4] == 1} {
		file delete [glob $path/public_html/$judulbaru.mp4]
		puthelp "PRIVMSG $chan :File\002 $judulbaru.mp4 \002deleted."
	}
}
proc apusmp3 {chan judulbaru} {
	global path
	if {[file exists $path/public_html/$judulbaru.mp3] == 1} {
		file delete [glob $path/public_html/$judulbaru.mp3]
		puthelp "PRIVMSG $chan :File\002 $judulbaru.mp3 \002deleted."
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
			putquick "PRIVMSG $chan :Your version is Up To Date. Version: \002$versi\002" ; return 0
		} else {
			set update [lindex $updated 3 end]
			putquick "PRIVMSG $chan :New version is available, starting upgrade to \002$update\002"
			after 1000
			putquick "PRIVMSG $chan :Done" ; return 0
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

proc search {nick uhost hand chan text} {
	global key id yturl
	regsub -all {\s+} $text "%20" text
	set text [string map {{"} {'} {`} {'}} $text]
	set url "https://www.googleapis.com/youtube/v3/search?part=snippet&fields=items(id(videoId))&maxResults=1&key=$key&q=$text"
	set ids [getinfo $url]
	for {set i 0} {$i < 1} {incr i} {
		set id [lindex $ids $i 1 1]
		set yturl "https://youtu.be/$id"
	}
}

proc getinfo { url } {
	set rawpage [::http::data [::http::geturl "$url" -timeout 5000]]
	if {[string length $rawpage] == 0} { puthelp "PRIVMSG $chan :Convert unsuccessful. Reason : No data or couldn't connect properly.";return 0}
	set ids [dict get [json::json2dict $rawpage] items]
}

proc autoinfo {nick host hand chan text} {
	global key id durasi judul
	set url "https://www.googleapis.com/youtube/v3/videos?id=$id&key=$key&part=snippet,contentDetails&fields=items(snippet(title),contentDetails(duration))"
	set ids [getinfo $url]
	set judul [encoding convertfrom [lindex $ids 0 1 1]]
	set durasi [lindex $ids 0 3 1]
	if {[regexp {^WARNING*} $durasi == 1]} {
		set durasi ""
	} else {
		regsub -all {PT|S} $durasi "" durasi
		regsub -all {H|M} $durasi ":" durasi
		if {[string index $durasi end-1] == ":" } {
			set sec [string index $durasi end]
			set trim [string range $durasi 0 end-1]
			set durasi ${trim}0$sec
		} elseif {[string index $durasi 0] == "0" } {
			set durasi "stream"
		} elseif {[string index $durasi end-2] != ":" } {
			set durasi "${durasi} seconds"
		} elseif {[string index $durasi end-5] == ":" } {
			set durasi "${durasi} hour"
		}
	}
}

bind pub n +playlist playlist:on
proc playlist:on {nick host hand chan text} {
	global allowplaylist
	set allowplaylist 1
	puthelp "PRIVMSG $chan :Playlist can't be downloaded now."
}
bind pub n -playlist playlist:off
proc playlist:off {nick host hand chan text} {
	global allowplaylist
	set allowplaylist 0
	puthelp "PRIVMSG $chan :Allow to download Playlist."
}

bind pub n .size ganti_size
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

	