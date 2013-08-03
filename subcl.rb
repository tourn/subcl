
require_relative './Subsonic'
require_relative './Mpc'

class Subcl

	def initialize
		@subsonic = Subsonic.new	
		@player = Mpc.new
	end

	def albumartUrl(v)
		current = @player.current
		puts @subsonic.albumartUrl() unless current.empty?
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
			puts "adding #{song}"
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
			puts "No matching song"
		else
			songs.each do |song|
				puts "#{song[:title]} by #{song[:artist]} on #{song[:album]}"
			end
		end
	end

	def searchAlbum(name)
		albums = @subsonic.albums(name)
		if(albums.size == 0)
			puts "No matching album"
		else
			albums.each do |album|
				puts "#{album[:name]} by #{album[:artist]}"
			end
		end
	end

	def searchArtist(name)
		artists = @subsonic.artists(name)
		if(artists.size == 0)
			puts "No matching artist"
		else
			artists.each do |artist|
				puts "#{artist[:name]}"
			end
		end
	end

end

def usage
	puts "USAGE"
	exit
end


#don't throw a huge stacktrace
trap("INT") {
 puts "\n"
 exit 
}

subcl = Subcl.new


usage if ARGV.size < 3

func = ARGV[0] + ARGV[1].capitalize

song = ARGV[2,ARGV.length-1].join(" ")

usage unless subcl.respond_to? func

subcl.send(func, song)
