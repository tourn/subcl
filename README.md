Subcl! a command-line client for [Subsonic][sub]
==================================================

Subcl is a semi-interactive command-line client for [Subsonic][sub]. It relies heavily on mpc, so much in fact, that you still have to use the mpc command for playback controls. Subcl only feeds mpd's playlist and keeps no track of it by itself.
If the song/album/artist you enter is unique, subcl will immediately return. If not, subcl will list all possible matches and ask you for the correct one interactively.

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
	sr | search aRtists [pattern]
	sl | search aLbums [pattern]
	ss | search songs [pattern]

	play: clear play queue and immediately start playing this
	pr | play aRtist [pattern]
	pl | play aLbum [pattern]
	ps | play song [pattern]

	queue: add this to the end of the play queue
	qr | queue aRtist [pattern]
	ql | queue aLbum [pattern]
	qs | queue song [pattern]

Status Codes
------------
- 1: An error occured communicating with the server
- 2: Your query returned no results

Issues
------
- no support for HTTPS (does mpd even support this?)

Coming up
---------
- interactive library browser using ncurses
- configurable verbosity
- possibility to switch interactiveness off, for scripting

[sub]: http://subsonic.org
