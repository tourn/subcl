require_relative 'Mpc'
require_relative 'Subsonic'
require_relative 'Configs'
require_relative 'Notify'

class Subcl
	attr_reader :player, :subsonic, :notifier

	def initialize(options = {})
		#default options
		@options = {
			:interactive => true,
			:tty => true,
			:insert => false
		}

		#overwrite defaults with given options
		@options.merge! options

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

	def queue(query, type, inArgs = {})
		args = {
			:clear => false, #whether to clear the playlist prior to adding songs
			:play => false, #whether to start the player after adding the songs
			:insert => false #whether to insert the songs after the current instead of the last one
		}
		args.merge! inArgs

		songs = case type
						when :song
							@subsonic.song(query)
						when :album
							@subsonic.albumSongs(query)
						when :artist
							@subsonic.artistSongs(query)
						when :playlist
							@subsonic.playlistSongs(query)
						end

		if songs.empty?
			noMatches
		end

		@player.clear if args[:clear]

		songs.shuffle! if @options[:shuffle]

		songs.each do |song|
			@player.add(song, args[:insert])
		end

		@player.play if args[:play]
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
