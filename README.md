Subcl! a command-line frontend for [Subsonic][sub]
==================================================

[sub]: http://subsonic.org

Requires ruby 1.8+ and mplayer

How to use:
-----------
 - .subcl file in your home directory (~/.subcl) contains:
   1. "server &lt;name of your subsonic server>"
   2. "username &lt;username for subsonic>"
   3. "password &lt;password for subsonic>"
 - currently supported commands:
   1. "artists" -- lists all artists available
   2. "albums &lt;artist name>" -- lists all albums for a given artist
   3. "qs &lt;song name>" -- queues a song
   4. "qa &lt;album name>" -- queues an album
   5. "queue" -- show the queue
   6. "play" -- plays each song in the queue (in order)

planned commands
----------------
lr list aRtists [pattern]
ll list aLbums [pattern]
ls list songs [pattern]

pr play aRtist [pattern]
pl play aLbum [pattern]
ps play song [pattern]

qr queue aRtist [pattern]
ql queue aLbum [pattern]
qs queue song [pattern]




Issues and TODO:
----------------
 - convert to using basic auth
 - more functionality (playing song/album on the fly)
 - modifying queue on the fly
 - support for other music players (cvlc, etc)
 - use mplayer, others in background mode (with sockets)
 - use subcl through socket
