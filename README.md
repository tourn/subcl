Subcl! a command-line client for [Subsonic][sub]
==================================================
Based on [winsbe01/subcl][origin]

Subcl is a semi-interactive command-line client for [Subsonic][sub]. It only
feeds mpd's playlist and keeps no track of it by itself. You can tell it to
play a song, album, artist or playlist. If your query is unique, subcl will
immediately return. If not, subcl will list all possible matches and ask you
for the correct one interactively.

Requirements
------------
- Ruby 2.0.0+
- mpd

Setup
-----
You can install subcl easily using gemcutter:

	gem install subcl

Create a .subcl file in your home directory (~/.subcl):

	server <url of your subsonic server>
	username <username for subsonic>
	password <password for subsonic>

Optionally it may contain:

	max_search_results <number, maximum search results, default 20>
	notify_method <one of below, notification system to use, default auto>
		auto - autmatically detect notifcation binary (may be slower)
		growlnotify
		notify-send
	random_song_count <number, count songs that are fetched for random-songs
		without argument, default 10>
	play_any_on_unknown_command true (if you don't supply any valid command, i.e. subcl foo, it will be interpreted as 'subcl play-any foo'
	wildcard_order song,album,artist,playlist (The order in which play-any will sort items)

Currently supported commands
----------------------------
Some commands are available in a short and a long format:
	[short command] | [long command] ATTRIBUTES

	[play] clear play queue and immediately start playing this
	pr | play-artist SEARCH_QUERY
	pl | play-album SEARCH_QUERY
	ps | play-song SEARCH_QUERY
	pp | play-playlist SEARCH_QUERY
	pn | play-any SEARCH_QUERY
	r  | play-random [COUNT]

	[queue-next] add this after the current song
	nr | queue-next-artist SEARCH_QUERY
	nl | queue-next-album SEARCH_QUERY
	ns | queue-next-song SEARCH_QUERY
	np | queue-next-playlist SEARCH_QUERY
	nn | queue-next-any SEARCH_QUERY

	[queue-last] add this to the end of the play queue
	lr | queue-last-artist SEARCH_QUERY
	ll | queue-last-album SEARCH_QUERY
	ls | queue-last-song SEARCH_QUERY
	lp | queue-last-playlist SEARCH_QUERY
	ln | queue-last-any SEARCH_QUERY

	albumart-url [SIZE] : Prints the url for the albumart of the currently
	playing song to stdout. Note that the url will contain your basic auth
	credentials in clear text.

	play
	pause
	toggle (play or pause)
	stop
	next
	previous
	rewind (go to start of song or previous song)

When choosing interactively, you can choose numbers, ranges, or 'all'. Examples:

	5
	3, 5, 8-12
	all

Notification System
-------------------
By default, if you call subcl from a place where it cannot output anything to
the tty (such as a shell script or a launcher), it will try to use your
system's notification mechanism to notify you of errors. This can be configured
via the notify_method in `~/.subcl`.


Status Codes
------------
- 1: An error occured communicating with the server
- 2: Your query returned no results
- 3: Invalid command line arguments
- 4: Broken configuration

Issues
------
- no support for HTTPS (does mpd even support this?)
- password is stored in plain text
- limited control over the mpd playlist, and the mpc playlist only shows URLs
	for songs it hasn't played yet (a possible fix for this might be generating
			playlists containing the ID3 tags and feeding it to mpd instead of the
			pure URLs)

Coming Up
---------
- wildcard play command (don't have to specify if it's a song, an album...)
	with configurable order for non-interactive mode (First, if it's a song name,
			play this song. otherwise, if it's an album...)
- currently playing command showing song metadata
- announce currently playing song via notification system

Ideas
-----
- podcasts
- make a useful search/browse command (maybe with curses?)
- configurable verbosity

[sub]: http://subsonic.org
[origin]: https://github.com/winsbe01/subcl
vim: set noexpandtab:
