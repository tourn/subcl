require_relative 'Mpc'
require_relative 'Subsonic'
require_relative 'Configs'
require_relative 'Notify'

class Subcl
	attr_reader :player, :subsonic

	def initialize(options = {})
		#default options
		@options = {
			:interactive => true,
			:tty => true
		}

		#overwrite defaults with given options
		@options.merge! (options)

		@subsonic = Subsonic.new	
		@subsonic.interactive = @options[:interactive]

		@player = Mpc.new
		@player.debug = @options[:debug]

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
		if songs.empty?
			noMatches
		end
		@player.clear if clear

		songs.shuffle! if @options[:shuffle]

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
			noMatches("song")
		else
			songs.each do |song|
				puts "#{song['title']} by #{song['artist']} on #{song['album']} (#{song['year']})"
			end
		end
	end

	def searchAlbum(name)
		albums = @subsonic.albums(name)
		if(albums.size == 0)
			noMatches("album")
		else
			albums.each do |album|
				puts "#{album['name']} by #{album['artist']} in #{album['year']}"
			end
		end
	end

	def searchArtist(name)
		artists = @subsonic.artists(name)
		if(artists.size == 0)
			noMatches("artist")
		else
			artists.each do |artist|
				puts "#{artist['name']}"
			end
		end
	end

	#prints an error that no matches were found on the fitting channel, the exits with code 2
	def noMatches(what = nil)
		if what
			message = "No matching #{what}"
		else
			message = "No matches"
		end

		if @options[:tty]
			$stderr.puts message
		else
			@notifier.notify(message) 
		end
		exit 2 
	end


end
