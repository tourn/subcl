require_relative './Subcl'
require 'optparse'

#don't throw a huge stacktrace
trap("INT") {
	puts "\n"
	exit
}

options = {}

if File.exist?('debug')
	puts "DEBUGGING"
	options[:debug] = true
end

#no idea how to get this variable from outside, so we'll just set it in the loop
usage = nil
OptionParser.new do |opts|
	opts.banner = "Usage: subcl [options] command"
	opts.separator ""
	opts.separator "Commands"
	opts.separator "    list to terminal"
	opts.separator "        search[-song|-album|-artist] <pattern>"
	opts.separator "        ss|sl|sr <pattern>"
	opts.separator "    clear queue and immediately start playing"
	opts.separator "        play[-song|-album|-artist|-playlist] <pattern>"
	opts.separator "        ps|pl|pr|pp <pattern>"
	opts.separator "    add to end of queue"
	opts.separator "        queue[-song|-album|-artist|-playlist] <pattern>"
	opts.separator "        qs|ql|qr|qp <pattern>"
	opts.separator "    albumart-url [size] - print url of albumart to terminal, "
	opts.separator "        optionally with a specified image size"
	opts.separator ""
	opts.separator "Options"

	usage = opts

	opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
		options[:verbose] = v
	end
	opts.on('-1', '--use-first', 'On multiple matches, use the first match instead of asking interactively') do
		options[:interactive] = false
	end
	opts.on('-s', '--shuffle', "Shuffle playlist before queueing") do
		options[:shuffle] = true
	end
	opts.on('-h', '--help', 'Display this screen') do
		puts opts
		exit
	end
	opts.on("--version", "Print version information") do
		puts Configs.new.app_version
		exit
	end

end.parse!

unless ARGV.size >= 1
	puts usage
	exit
end

unless system('tty -s')
	#not running in a tty, so no use for interactivity
	options[:tty] = false
	options[:interactive] = false
end

subcl = Subcl.new options

arg = ARGV[1,ARGV.length-1].join(" ") #put rest of args together so no quotes are required


case ARGV[0].downcase
when /play-song|ps/
	subcl.playSong(arg)
when /play-artist|pr/
	subcl.playArtist(arg)
when /play-album|pl/
	subcl.playAlbum(arg)
when /play-paylist|pp/
	subcl.playPlaylist(arg)
when /queue-song|qs/
	subcl.queueSong(arg)
when /queue-artist|qr/
	subcl.queueArtist(arg)
when /queue-album|ql/
	subcl.queueAlbum(arg)
when /queue-playlist|qp/
	subcl.queuePlaylist(arg)
when /search-song|ss/
	subcl.searchSong(arg)
when /search-artist|sr/
	subcl.searchArtist(arg)
when /search-album|sl/
	subcl.searchAlbum(arg)
when "albumart-url"
	arg = nil if arg.empty?
	puts subcl.albumartUrl(arg)
when /album-list|al/
	subcl.subsonic.albumlist
else
	puts usage
end
