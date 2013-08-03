
require './Subsonic'
require './Mpc'

class Subcl

	def initialize
		@subsonic = Subsonic.new	
		@player = Mpc.new
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
		@subsonic.artist(name).albums.each do |album|
			album.songs.each do |song|
				@player.add(song)
			end
		end
	end

	def queueAlbum(name)
		@subsonic.album(name).songs.each do |song|
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
