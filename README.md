Subcl! a command-line frontend for [Subsonic][sub]
==================================================

[sub]: http://subsonic.org

Requires ruby 1.8+ and mplayer

How to use:
-----------
 - .subcl file in your home directory (~/.subcl) contains:
   1. "server &gt;name of your subsonic server>"
   2. "username &gt;username for subsonic>"
   3. "password &gt;password for subsonic>"
 - currently supported commands:
   1. "qs &gt;song name>" -- queues a song
   2. "qa &gt;album name>" -- queues an album
   3. "play" -- plays each song in the queue (in order)

Issues and TODO:
----------------
 - convert to using basic auth
 - more functionality (playing song/album on the fly)
 - modifying queue on the fly
 - support for other music players (cvlc, etc)
 - use mplayer, others in background mode (with sockets)
 - use subcl through socket
