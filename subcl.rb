
require_relative './Subsonic'
require_relative './Mpc'

class Subcl

	def initialize
		@subsonic = Subsonic.new	
		@player = Mpc.new
	end

	def albumart(v)
		current = @player.current
		puts @subsonic.albumart() unless current.empty?
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
		@subsonic.getArtistSongs(name).each do |song|
			puts "adding #{song}"
			@player.add(song)
		end
	end

	def queueAlbum(name)
		@subsonic.getAlbumSongs(name).each do |song|
			@player.add(song)
		end
	end

	def queueSong(name)
		@player.add(
			@subsonic.getSong(name)
		)
	end

end

def usage
	puts "USAGE"
	exit
end



subcl = Subcl.new


usage if ARGV.size < 3

func = ARGV[0] + ARGV[1].capitalize

song = ARGV[2,ARGV.length-1].join(" ")

usage unless subcl.respond_to? func

subcl.send(func, song)
