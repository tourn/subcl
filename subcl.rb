require_relative './Subsonic'
require_relative './Mpc'
require 'optparse'

class Subcl

	def initialize
		@subsonic = Subsonic.new	
		@player = Mpc.new
	end

	def albumartUrl
		current = @player.current
		puts @subsonic.albumartUrl(current) unless current.empty?
	end

	def playSong(name)
		@player.clear
		queueSong(name)
		@player.play
	end

	def playAlbum(name)
		@player.clear
		queueAlbum(name)
		@player.play
	end

	def playArtist(name)
		@player.clear
		queueArtist(name)
		@player.play
	end

	def queueArtist(name)
		@subsonic.artistSongs(name).each do |song|
			#puts "adding #{song}"
			@player.add(song)
		end
	end

	def queueAlbum(name)
		@subsonic.albumSongs(name).each do |song|
			@player.add(song)
		end
	end

	def queueSong(name)
		@player.add(
			@subsonic.song(name)
		)
	end

	def searchSong(name)
		songs = @subsonic.songs(name)
		if(songs.size == 0)
			$stderr.puts "No matching song"
		else
			songs.each do |song|
				puts "#{song[:title]} by #{song[:artist]} on #{song[:album]}"
			end
		end
	end

	def searchAlbum(name)
		albums = @subsonic.albums(name)
		if(albums.size == 0)
			$stderr.puts "No matching album"
		else
			albums.each do |album|
				puts "#{album[:name]} by #{album[:artist]}"
			end
		end
	end

	def searchArtist(name)
		artists = @subsonic.artists(name)
		if(artists.size == 0)
			$stderr.puts "No matching artist"
		else
			artists.each do |artist|
				puts "#{artist[:name]}"
			end
		end
	end

end



#don't throw a huge stacktrace
trap("INT") {
 puts "\n"
 exit 
}


options = {}

#no idea how to get this variable from outside, so we'll just set it in the loop
usage = nil
OptionParser.new do |opts|
  opts.banner = "Usage: subcl [options] command"
  opts.separator ""
  opts.separator "Commands"
  opts.separator "	search[-song|-album|-artist] <pattern> - list to terminal"
  opts.separator "	play[-song|-album|-artist] <pattern> - clear queue and immediately start playing"
  opts.separator "	queue[-song|-album|-artist] <pattern> - add to end of queue"
  opts.separator "	albumart-url - print url of albumart to terminal"
  opts.separator ""
  opts.separator "Options"

	usage = opts

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
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

subcl = Subcl.new

unless ARGV.size >= 2
	puts usage
	exit
end

song = ARGV[1,ARGV.length-1].join(" ") #put rest of args together so no quotes are required

#this hurts my eyes AND my heart
case ARGV[0].downcase
when 'play'
	subcl.playAny(song)
when 'play-song'
	subcl.playSong(song)
when 'play-artist'
	subcl.playArtist(song)
when 'play-album'
	subcl.playAlbum(song)
when 'queue'
	subcl.queueAny(song)
when 'queue-song'
	subcl.queueSong(song)
when 'queue-artist'
	subcl.queueArtist(song)
when 'queue-album'
	subcl.queueAlbum(song)
when 'search'
	subcl.searchAny(song)
when 'search-song'
	subcl.searchSong(song)
when 'search-artist'
	subcl.searchArtist(song)
when 'search-album'
	subcl.searchAlbum(song)
when 'p'
	subcl.playAny(song)
when 'ps'
	subcl.playSong(song)
when 'pr'
	subcl.playArtist(song)
when 'pl'
	subcl.playAlbum(song)
when 'q'
	subcl.queueAny(song)
when 'qs'
	subcl.queueSong(song)
when 'qr'
	subcl.queueArtist(song)
when 'ql'
	subcl.queueAlbum(song)
when 's'
	subcl.searchAny(song)
when 'ss'
	subcl.searchSong(song)
when 'sr'
	subcl.searchArtist(song)
when 'sl'
	subcl.searchAlbum(song)
when "albumart-url"
	puts subcl.albumartUrl
else
	puts "YOU FAILED!"
	puts usage
end
