require_relative 'Mpc'
require_relative 'Subsonic'
require_relative 'Configs'
require_relative 'Notify'

class Subcl
	attr_reader :player, :subsonic
	attr_accessor :shuffle

	def initialize
		@subsonic = Subsonic.new	
		@player = Mpc.new
		@notifier = Notify.new Configs.new.notifyMethod
	end

	def albumartUrl(size = nil)
		current = @player.current
		puts @subsonic.albumartUrl(current, size) unless current.empty?
	end

	def playSong(name)
		queueSong(name, true)
		@player.play
	end

	def playAlbum(name)
		queueAlbum(name, true)
		@player.play
	end

	def playArtist(name)
		queueArtist(name, true)
		@player.play
	end

	def playPlaylist(name)
		queuePlaylist(name, true)
		@player.play
	end

	def queue(songs, clear = false)
		exit 2 if songs.empty?
		@player.clear if clear

		songs.shuffle! if @shuffle

		songs.each do |song|
			@player.add(song)
		end
	end

	def queueArtist(name, clear = false)
		queue(@subsonic.artistSongs(name), clear)
	end

	def queueAlbum(name, clear = false)
		queue(@subsonic.albumSongs(name), clear)
	end

	def queueSong(name, clear = false)
		queue(@subsonic.song(name), clear)
	end

	def queuePlaylist(name, clear = false)
		queue(@subsonic.playlistSongs(name), clear)
	end

	def searchSong(name)
		songs = @subsonic.songs(name)
		if(songs.size == 0)
			$stderr.puts "No matching song"
			exit 2
		else
			songs.each do |song|
				puts "#{song['title']} by #{song['artist']} on #{song['album']} (#{song['year']})"
			end
		end
	end

	def searchAlbum(name)
		albums = @subsonic.albums(name)
		if(albums.size == 0)
			$stderr.puts "No matching album"
			exit 2
		else
			albums.each do |album|
				puts "#{album['name']} by #{album['artist']} in #{album['year']}"
			end
		end
	end

	def searchArtist(name)
		artists = @subsonic.artists(name)
		if(artists.size == 0)
			$stderr.puts "No matching artist"
			exit 2
		else
			artists.each do |artist|
				puts "#{artist['name']}"
			end
		end
	end

end
