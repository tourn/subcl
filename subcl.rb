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
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: subcl [options] command"
  opts.separator ""
  opts.separator "Commands"
  opts.separator "	search[-song|-album|-artist] <pattern> - list to terminal"
  opts.separator "	play[-song|-album|-artist] <pattern> - clear queue and immediately start playing"
  opts.separator "	queue[-song|-album|-artist] <pattern> - add to end of queue"
  opts.separator "	albumart-url - print url of albumart to terminal"
  opts.separator ""
  opts.separator "Options"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("--version", "Print version information") do |v|
		puts Configs.new.app_version
		exit
  end
end.parse!

subcl = Subcl.new

case ARGV[0].downcase
#way too complicated command-parsing ahead
when /^(ss|sr|sl|ps|pr|pl|qs|qr|ql|s|p|q)|(search|play|queue)(-song|-album|-artist)?$/
	song = ARGV[1,ARGV.length-1].join(" ") #put rest of args together so no quotes are required
	if $1 #short command
		case $1[0]
		when "s"
			cmd = "search"
		when "p"
			cmd = "play"
		when "q"
			cmd = "query"
		end

		case $1[1]
		when "s"
			object = "song"
		when "r"
			object = "artist"
		when "l"
			object = "album"
		end

		puts "short command parsed:"
		p cmd
		p object
	end

	cmd ||= $2
	object ||= $3

	p cmd
	p object

	if object.nil? #no word after the dash in long-command
		subcl.send(cmd, song)
	else
		func = cmd + object.sub(/^-/,'').capitalize
		subcl.send(func, song)
	end
when "albumart-url"
	puts subcl.albumartUrl
else
	puts opt_parser
end
