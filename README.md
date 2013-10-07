Subcl! a command-line client for [Subsonic][sub]
==================================================

Subcl is a semi-interactive command-line client for [Subsonic][sub]. It relies
heavily on mpc, so much in fact, that you still have to use the mpc command for
playback controls. Subcl only feeds mpd's playlist and keeps no track of it by
itself. (Although basically it should be possible to call another command line
		client that works in a similar fashion) If the song/album/artist you enter
is unique, subcl will immediately return. If not, subcl will list all possible
matches and ask you for the correct one interactively.

Requirements
------------
- Ruby 1.8+
- mpd
- mpc

Setup
-----
.subcl file in your home directory (~/.subcl) contains:

	server &lt;name of your subsonic server>
	username &lt;username for subsonic>
	password &lt;password for subsonic>
	max_search_results &lt;maximum search results, optional, default 20>

Currently supported commands
----------------------------
	search: print entries to console
	sr | search-aRtist [pattern]
	sl | search-aLbum [pattern]
	ss | search-song [pattern]

	play: clear play queue and immediately start playing this
	pr | play-aRtist [pattern]
	pl | play-aLbum [pattern]
	ps | play-song [pattern]
	pp | play-playlist [pattern]

	queue: add this to the end of the play queue
	qr | queue-aRtist [pattern]
	ql | queue-aLbum [pattern]
	qs | queue-song [pattern]
	qp | queue-playlist [pattern]

When choosing interactively, you can choose numbers, ranges, or 'all'

	Examples:
	5
	3, 5, 8-12
	all

Status Codes
------------
- 1: An error occured communicating with the server
- 2: Your query returned no results

Issues
------
- no support for HTTPS (does mpd even support this?)
- password is stored in plain text
- no control over the mpc playlist, and the mpc playlist only shows URLs for
	songs it hasn't played yet (a possible fix for this might be generating
			playlists containing the ID3 tags and feeding it to mpd instead of the
			pure URLs)

Coming up
---------
- podcasts
- search-playlist command or something similar
- shuffle trigger, to shuffle the entries before adding them to the playlist
- logging / integration of notification system for error messages which can't be
	sent to tty
- make search command more useful
- additional queue command to add after the current song instead of the end of
	the list
- passing through of non-subcl commands (play, toggle, random) to mpc, so you
	don't have to remember which executable to call
- configurable verbosity
- interactive library browser using ncurses

[sub]: http://subsonic.org
