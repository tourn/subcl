require_relative './Subcl'
require 'optparse'

#don't throw a huge stacktrace
trap("INT") {
 puts "\n"
 exit 
}

subcl = Subcl.new

if File.exist?('debug')
	puts "DEBUGGING"
	subcl.player.debug = true
end

options = {}

#no idea how to get this variable from outside, so we'll just set it in the loop
usage = nil
OptionParser.new do |opts|
  opts.banner = "Usage: subcl [options] command"
  opts.separator ""
  opts.separator "Commands"
  opts.separator "	search[-song|-album|-artist] <pattern> - list to terminal"
  opts.separator "	ss|sl|sr <pattern> - list to terminal"
  opts.separator "	play[-song|-album|-artist] <pattern> - clear queue and immediately start playing"
  opts.separator "	ps|pl|pr <pattern> - clear queue and immediately start playing"
  opts.separator "	queue[-song|-album|-artist] <pattern> - add to end of queue"
  opts.separator "	qs|ql|qr <pattern> - add to end of queue"
  opts.separator "	albumart-url - print url of albumart to terminal"
  opts.separator ""
  opts.separator "Options"

	usage = opts

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
	opts.on('-1', '--use-first', 'On multiple matches, use the first match instead of asking interactively') do
		subcl.subsonic.interactive = false
	end
  opts.on("--version", "Print version information") do
		puts Configs.new.app_version
		exit
  end
	opts.on('-h', '--help', 'Display this screen') do
		puts opts
		exit
	end

end.parse!

unless ARGV.size >= 1
	puts usage
	exit
end

unless system('tty -s')
	#not running in a tty, so no use for interactivity
	subcl.subsonic.interactive = false
end

song = ARGV[1,ARGV.length-1].join(" ") #put rest of args together so no quotes are required

case ARGV[0].downcase
when /play-song|ps/
	subcl.playSong(song)
when /play-artist|pr/
	subcl.playArtist(song)
when /play-album|pl/
	subcl.playAlbum(song)
when /play-paylist|pp/
	subcl.playPlaylist(song)
when /queue-song|qs/
	subcl.queueSong(song)
when /queue-artist|qr/
	subcl.queueArtist(song)
when /queue-album|ql/
	subcl.queueAlbum(song)
when /queue-playlist|qp/
	subcl.queuePlaylist(song)
when /search-song|ss/
	subcl.searchSong(song)
when /search-artist|sr/
	subcl.searchArtist(song)
when /search-album|sl/
	subcl.searchAlbum(song)
when "albumart-url"
	puts subcl.albumartUrl
when /album-list|al/
	subcl.subsonic.albumlist
else
	puts usage
end
