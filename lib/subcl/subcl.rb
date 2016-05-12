
class Subcl
  attr_accessor :player, :api, :notifier, :configs

  def initialize(options = {})
    #TODO merge options and configs
    @options = {
      :interactive => true,
      :tty => true,
      :insert => false,
      :out_stream => STDOUT,
      :err_stream => STDERR,
      :wildcard_order => %i{playlist album artist song}
    }.merge! options

    @out = @options[:out_stream]
    @err = @options[:err_stream]

    begin
      @configs = Configs.new
    rescue => e
      @err.puts "Error initializing config"
      @err.puts e.message
      exit 4
    end

    @configs[:random_song_count] = @options[:random_song_count] if @options[:random_song_count]

    @player = nil

    @api = @options[:mock_api] || SubsonicAPI.new(@configs)

    @notifier = Notify.new @configs[:notify_method]

    @display = {
      :song => proc { |song|
        @out.puts sprintf "%-20.20s %-20.20s %-20.20s %-4.4s", song[:title], song[:artist], song[:album], song[:year]
      },
      :album => proc { |album|
        @out.puts sprintf "%-30.30s %-30.30s  %-4.4s", album[:name], album[:artist], album[:year]
      },
      :artist => proc { |artist|
        @out.puts "#{artist[:name]}"
      },
      :playlist => proc { |playlist|
        @out.puts "#{playlist[:name]} by #{playlist[:owner]}"
      },
      :any => proc { |thing|
        #TODO this works, but looks confusing when multiple types are displayed
        @display[thing[:type]].call(thing)
      }
    }
  end

  def get_player()
    if @player == nil
      @player = @options[:mock_player] || Player.new
    end
    @player
  end

  def albumart_url(size = nil)
    current = get_player.current_song
    @api.albumart_url(current.file, size) if current
  end

  def queue(query, type, inArgs = {})
    args = {
      :clear => false, #whether to clear the playlist prior to adding songs
      :play => false, #whether to start the player after adding the songs
      :insert => false #whether to insert the songs after the current instead of the last one
    }
    args.merge! inArgs

    if @options[:current]
      query = case type
              when :album
                get_player.current_song.album
              when :artist
                get_player.current_song.artist
              else
                raise ArgumentError, "'current' option can only be used with albums or artists."
              end
    end

    songs = case type
            when :randomSong
              begin
                count = query.empty? ? @configs[:random_song_count] : query
                @api.random_songs(count)
              rescue ArgumentError
                raise ArgumentError, "random-songs takes an integer as argument"
              end
            else #song, album, artist, playlist, any
              entities = @api.search(query, type)
              entities.sort!(&any_sorter(query)) if type == :any
              entities = invoke_picker(entities, &@display[type])
              @api.get_songs(entities)
            end

    no_matches if songs.empty?

    get_player.clearstop if args[:clear]

    songs.shuffle! if @options[:shuffle]

    songs.each do |song|
      get_player.add(song, args[:insert])
    end

    get_player.play if args[:play]
  end

  #returns a sorter proc for two hashes with the attribute :type and :name
  #
  #it will use split(" ") on query and then count how many words of query each
  #:name contains. If two hashes have the same amount of query words,
  #@options[:wildcard_order] is used
  #
  #the closest matches will be at the beginning
  #
  def any_sorter(query)
    #TODO do things with query! find the things that match the query the most
    order = @options[:wildcard_order]
    lambda do |e1, e2|
      cmp = match_score(e1, query) <=> match_score(e2, query)
      if cmp == 0
        out = order.index(e1[:type]) <=> order.index(e2[:type])
        out
      else
        -cmp
      end
    end
  end

  def match_score(entity, query)
    query.split(' ').inject(0) do |memo, word|
      memo + (entity[:name].downcase.include?(word.downcase) ? 1 : 0)
    end
  end

  def print(name, type)
    entities = @api.search(name, type)
    no_matches(type) if entities.empty?
    entities.each do |entity|
      @display[type].call(entity)
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
      @err.puts message
    else
      @notifier.notify(message)
    end
    exit 2
  end

  def testNotify
    @notifier.notify("Hi!")
  end

  def albumlist
    @api.albumlist.each do |album|
      @display[:album].call(album)
    end
  end

  #show an interactive picker that lists every element of the array using &display_proc
  #The user can then choose one, many or no of the elements which will be returned as array
  def invoke_picker(array, &display_proc)
    return array if array.length <= 1
    return [array.first] unless @options[:interactive]
    return Picker.new(array).pick(&display_proc)
  end

  def status(format_string = "")
    format_string = "%artist - %title" if format_string.empty?

    state = get_player.status[:state]
    case state
    when :pause
      return "paused"
    when :stop
      return "stopped"
    when :play
      song_id = /id=(\d*)/.match(get_player.current_song.file)[1]
      info = @api.song_info(song_id)
      return format(info, format_string)
    end
  rescue SubclError
    return "disconnected"
  end

  def format(song, format_string)
    song.each do |key, val|
      format_string.sub!('%'+key.to_s, val)
    end
    return format_string
  end

  #these methods will be passed through to the underlying player
  PLAYER_METHODS = %i{play pause toggle stop next previous rewind}
  def method_missing(name, args)
    raise NoMethodError unless PLAYER_METHODS.include? name
    get_player.send(name)
  end

end
