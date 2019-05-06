######################################################
### Settings ###
######################################################

# This is link for download the mp3 or mp4 file.
set linkdl "http://mp3.rhe.name/~mp3/"

# Your public_html folder patch
set path "/home/mp3"

# Set Your Youtube API Key
set key "AIzaSyBlnL8h7FnukIEj9_QLtunU6x2AIO0H9vQ"

# M4a Size Limit for download. (Set it blank for free size)
# Example: set mpatsize ""
if {![info exist mpatasize]} { set mpatasize "20m" }

# Allow Playlist download or not.
# 0 = Allowed, 1 = Not allowed.
if {![info exist allowplaylistm4a]} { set allowplaylistm4a "1" }

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

bind pub - .m4a mpat
bind pub n +playlist4a playlist:m4a:on
bind pub n -playlist4a playlist:m4a:off
bind pub n .playlist4a playlist:m4a:list
bind pub n .size4a ganti_sizempata

## M4a ##
proc mpat { nick host hand chan text } {
	global allowplaylistm4a 
	if {![channel get $chan ytconvert]} { return 0 }
	if {[lindex $text 0] == ""} { puthelp "PRIVMSG $chan :Syntax: \002.m4a <title + singer>/<link>\002." ; return 0 }
	if {[string length $text] < 3} { puthelp "PRIVMSG $chan :Maximum 3 characters for Download." ; return 0 }
	if {[string match "*stream*" [string tolower $text]]} { puthelp "PRIVMSG $chan :Streaming is not allowed." ; return 0 }
	if {$allowplaylistm4a == 1} {
		if {[string match "*playlist?list*" [string tolower $text]]} { puthelp "PRIVMSG $chan :Playlist is not allowed." ; return 0 }
	}
	if {![string match "*http*" [lindex $text 0]]} {
		mpattext $nick $host $hand $chan $text
	} else {
		mpatlink $nick $host $hand $chan $text
	}
}

proc mpattext { nick host hand chan text } {
	global path linkdl judulbaru durasi id judul yturl mpatasize
	if {[string match "* -*" [string tolower $text]]} { regsub {\-} $text {} text }
	searchm4a $nick $host $hand $chan $text
	autoinfom4a $nick $host $hand $chan $text
	if {$durasi == "stream"} { puthelp "PRIVMSG $chan :Streaming is not allowed." ; return 0 }
	if {[string match "*:*" $durasi]} { set durasi "$durasi minutes" }
	set judulbaru [string map {" " "_" "ÂŽ" "" "ðŸŽ¶" "" "ðŸŽ§" "" "ðŸŽµ" "" "Ÿ" "" "¶" "" "?" "" "ð" "" "µ" "" {¤} {} {?} "" {`} "" {"} "" {} "" {?} "" {%} "persen" {[} "(" {]} ")" {|_} "" {/} "_" {|} "-" {/_} "-" {"_} "" {#} "" "é" "e"} $judul]
	putquick "PRIVMSG $chan :Trying to convert \002$judul\002 please wait..."
	if {$mpatasize != ""} {
		if {![matchattr $nick n]} {
			catch {exec youtube-dl --max-filesize $mpatsize --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format m4a --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$yturl"} mptigaruncmd
		} else {
			catch {exec youtube-dl --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format m4a --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$yturl"} mptigaruncmd
		}
	} else {
		catch {exec youtube-dl --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format m4a --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$yturl"} mptigaruncmd
	}
	foreach line [split $mptigaruncmd "\n"] { 
		if {[string match "ERROR:*" $line]} { puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: $line" ; return 0 }
		if {[string match "*File is larger than max-filesize*" $line]} { puthelp "PRIVMSG $chan :File is larger than\002 $mpatsize\002. (Only owner can Download big file)" ; return 0 }
		if {[string match "*unable to download video data*" $line]} { puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: Unable to download video data at this time. (\002Just try again\002)" ; return 0 }
	}
	if {[file exists $path/public_html/$judulbaru.m4a] == 1} {
		set besar [fixform [file size "$path/public_html/$judulbaru.m4a"]]
		putquick "PRIVMSG $chan :Download Link: $linkdl$judulbaru.m4a \[Size: \002$besar\002\] \[Duration: \002$durasi\002\] | (Will be deleted in\002 30 minutes\002)"
		timer 30 [list apusm4a $chan $judulbaru]
	} else {
		puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: An unexpected error."
	}
}

proc mpatlink { nick host hand chan text } {
	global path linkdl judulbaru durasi id judul mpatsize
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
	if {$mpatasize != ""} {
		if {![matchattr $nick n]} {
			catch {exec youtube-dl --max-filesize $mpatsize --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format m4a --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$text"} mptigaruncmdd
		} else {
			catch {exec youtube-dl --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format m4a --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$text"} mptigaruncmdd
		}
	} else {
		catch {exec youtube-dl --prefer-ffmpeg --no-playlist --no-mtime --ignore-config --geo-bypass --abort-on-error --no-color --no-mark-watched --no-call-home --no-warnings --youtube-skip-dash-manifest -w -x --audio-format m4a --audio-quality 0 -o "$path/public_html/$judulbaru.%(ext)s" "$text"} mptigaruncmdd
	}
	foreach line [split $mptigaruncmdd "\n"] {
		if {[string match "ERROR:*" $line]} { puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: $line" ; return 0 }
		if {[string match "*File is larger than max-filesize*" $line]} { puthelp "PRIVMSG $chan :File is larger than\002 $mpatsize\002. (Only owner can Download big file)" ; return 0 }
		if {[string match "*unable to download video data*" $line]} { puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: Unable to download video data at this time. (\002Just try again\002)" ; return 0 }
	}
	if {[file exists $path/public_html/$judulbaru.m4a] == 1} {
		set besar [fixform [file size "$path/public_html/$judulbaru.m4a"]]
		putquick "PRIVMSG $chan :Download Link: $linkdl$judulbaru.m4a \[Size: \002$besar\002\] \[Duration: \002$durasi\002\] | (Will be deleted in\002 30 minutes\002)"
		timer 30 [list apusm4a $chan $judulbaru]
	} else {
		puthelp "PRIVMSG $chan :Convert unsuccessful. Reason: An unexpected error."
	}
}

## Auto Delete File ##
proc apusm4a {chan judulbaru} {
	global path
	if {[file exists $path/public_html/$judulbaru.mp4] == 1} {
		file delete [glob $path/public_html/$judulbaru.mp4]
		puthelp "PRIVMSG $chan :File\002 $judulbaru.mp4 \002deleted."
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

proc searchm4a {nick uhost hand chan text} {
	global key id yturl
	regsub -all {\s+} $text "%20" text
	set text [string map {{"} {'} {`} {'}} $text]
	set url "https://www.googleapis.com/youtube/v3/search?part=snippet&fields=items(id(videoId))&maxResults=1&key=$key&q=$text"
	set ids [getinfom4a $url]
	set id [lindex $ids 0 1 1]
	set yturl "https://youtu.be/$id"
}

proc getinfom4a { url } {
	set rawpage [::http::data [::http::geturl "$url" -timeout 5000]]
	if {[string length $rawpage] == 0} { puthelp "PRIVMSG $chan :Convert unsuccessful. Reason : No data or couldn't connect properly.";return 0}
	set ids [dict get [json::json2dict $rawpage] items]
}

proc autoinfom4a {nick host hand chan text} {
	global key id durasi judul
	set url "https://www.googleapis.com/youtube/v3/videos?id=$id&key=$key&part=snippet,contentDetails&fields=items(snippet(title),contentDetails(duration))"
	set ids [getinfom4a $url]
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

proc playlist:m4a:on {nick host hand chan text} {
	global allowplaylistm4a
	set allowplaylistm4a 1
	puthelp "PRIVMSG $chan :Playlist can't be downloaded now."
}
proc playlist:m4a:off {nick host hand chan text} {
	global allowplaylistm4a
	set allowplaylistm4a 0
	puthelp "PRIVMSG $chan :Allow to download Playlist."
}
proc playlist:m4a:list {nick host hand chan text} {
	global allowplaylistm4a
	if {$allowplaylistm4a == 0} { puthelp "PRIVMSG $chan :Playlist is \002Allowed\002" ; return }
	if {$allowplaylistm4a == 1} { puthelp "PRIVMSG $chan :Playlist is \002Not allowed\002" ; return }
}

proc ganti_sizempata {nick host hand chan text} {
	global mpatasize
	if {[lindex $text 0] == ""} {
		puthelp "PRIVMSG $chan :Syntax:\002.size4a m4a <size>"
		puthelp "PRIVMSG $chan :Syntax:\002.size4a <off>"
		return 0
	}
	if {[lindex $text 0] == "m4a"} { 
		set mpatasize [lindex $text 1]
		puthelp "PRIVMSG $chan :M4a download size change to \002$mpatasize\002."
	} elseif {[lindex $text 0] == "off"} {
		set mpatasize ""
		puthelp "PRIVMSG $chan :Download size now is \002FREE\002."
	} elseif {[lindex $text 0] == "list"} {
		puthelp "PRIVMSG $chan :M4a size limit is \002$mpatasize\002"
	}
}
