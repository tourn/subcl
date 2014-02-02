require_relative 'mpc'
require_relative 'subsonic'
require_relative 'configs'
require_relative 'notify'

class Subcl
  attr_reader :player, :subsonic, :notifier

  def initialize(options = {})
    #default options
    @options = {
      :interactive => true,
      :tty => true,
      :insert => false,
      :out_stream => STDOUT,
      :err_stream => STDERR
    }

    #overwrite defaults with given options
    @options.merge! options

    begin
    @configs = Configs.new
    rescue => e
      @options[:err_stream].puts "Error initializing config"
      @options[:err_stream].puts e.message
      exit 4
    end

    @player = Mpc.new
    @player.debug = @options[:debug]

    @notifier = Notify.new @configs.notifyMethod

    @display = {
      :song => proc { |song|
        @options[:err_stream].puts "#{song['title']} by #{song['artist']} on #{song['album']} (#{song['year']})"
      },
      :album => proc { |album|
        @options[:err_stream].puts "#{album['name']} by #{album['artist']} in #{album['year']}"
      },
      :artist => proc { |artist|
        @options[:err_stream].puts "#{artist['name']}"
      },
      :playlist => proc { |playlist|
        @options[:err_stream].puts "#{playlist[:name]} by #{playlist[:owner]}"
      },
    }

    @subsonic = Subsonic.new(@configs, @display)
    @subsonic.interactive = @options[:interactive]

  end

  def albumart_url(size = nil)
    current = @player.current
    @options[:out_stream].puts @subsonic.albumart_url(current, size) unless current.empty?
  end

  def queue(query, type, inArgs = {})
    args = {
      :clear => false, #whether to clear the playlist prior to adding songs
      :play => false, #whether to start the player after adding the songs
      :insert => false #whether to insert the songs after the current instead of the last one
    }
    args.merge! inArgs

    if @options[:current]
      unless [:album, :artist].include? type
        raise ArgumentError, "'current' option can only be used with albums or artists."
      end
      query = @player.current type
    end

    songs = case type
            when :song
              @subsonic.song(query)
            when :album
              @subsonic.album_songs(query)
            when :artist
              @subsonic.artist_songs(query)
            when :playlist
              @subsonic.playlist_songs(query)
            when :randomSong
              begin
                @subsonic.random_songs(query)
              rescue ArgumentError
                raise ArgumentError, "random-songs takes an integer as argument"
              end
            end

    if songs.empty?
      no_matches
    end

    @player.clear if args[:clear]

    songs.shuffle! if @options[:shuffle]

    songs.each do |song|
      @player.add(song, args[:insert])
    end

    @player.play if args[:play]
  end

  def search_song(name)
    songs = @subsonic.songs(name)
    if(songs.size == 0)
      no_matches("song")
    else
      songs.each do |song|
        @display[:song].call(song)
      end
    end
  end

  def search_album(name)
    albums = @subsonic.albums(name)
    if(albums.size == 0)
      no_matches("album")
    else
      albums.each do |album|
        @display[:album].call(album)
      end
    end
  end

  def search_artist(name)
    artists = @subsonic.artists(name)
    if(artists.size == 0)
      no_matches("artist")
    else
      artists.each do |artist|
        @display[:artist].call(artist)
      end
    end
  end

  #print an error that no matches were found, then exit with code 2
  def no_matches(what = nil)
    if what
      message = "No matching #{what}"
    else
      message = "No matches"
    end

    if @options[:tty]
      @options[:err_stream].puts message
    else
      @notifier.notify(message)
    end
    exit 2
  end

  def testNotify
    @notifier.notify("Hi!")
  end

  def albumlist
    @subsonic.albumlist.each &@display[:album]
  end


end
