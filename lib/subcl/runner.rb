require 'optparse'

class Runner
  def initialize(options = {})
    @options = {
      :tty => true,
      :out_stream => STDOUT,
      :err_stream => STDERR,
      :mock_player => nil,
      :mock_api => nil
    }.merge! options

    #TODO refactor this away
    if File.exist?('debug')
      puts "DEBUGGING"
      @options[:debug] = true
    end
  end

  def parse_options! args
    OptionParser.new do |opts|
      opts.banner = "Usage: subcl [options] command"
      opts.separator %{
    Queue Commands
      clear queue and immediately start playing
          play[-song|-album|-artist|-playlist] <pattern>
          ps|pl|pr|pp <pattern>
      clear queue and immediately start playing random songs
          play-random <count, default 10>
          r <count, default 10>
      add to end of queue
          queue-last[-song|-album|-artist|-playlist] <pattern>
          ls|ll|lr|lp <pattern>
      add after the current song
          queue-next[-song|-album|-artist|-playlist] <pattern>
          ns|nl|nr|np <pattern>
      albumart-url [size] - print url of albumart to terminal,
          optionally with a specified image size

    Playback Commands
      play
      pause
      toggle (play when pause, pause when played)
      stop
      next
      previous
      rewind (get to start of song, or previous song when at start)

    Options }

      @usage = opts

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        @options[:verbose] = v
      end
      opts.on('-1', '--use-first', 'On multiple matches, use the first match instead of asking interactively') do
        @options[:interactive] = false
      end
      opts.on('-s', '--shuffle', "Shuffle playlist before queueing") do
        @options[:shuffle] = true
      end
      opts.on('-c', '--current', 'Use info currently playing song instead of commandline argument') do
        @options[:current] = true
      end
      opts.on('-h', '--help', 'Display this screen') do
        @options[:out_stream].puts opts
        exit
      end
      opts.on("--version", "Print version information") do
        @options[:out_stream].puts Subcl::VERSION
        exit
      end

    end.parse! args
  end

  def run(args)
    LOGGER.debug { "args = #{args}" }

    parse_options!(args)

    LOGGER.debug { "args = #{args}" }

    unless args.size >= 1
      @options[:err_stream].puts @usage
      exit 3
    end

    unless system('tty -s')
      #not running in a tty, so no use for interactivity
      @options[:tty] = false
      @options[:interactive] = false
    end

    subcl = Subcl.new @options

    arg = args[1,args.length-1].join(" ") #put rest of args together so no quotes are required

    command = args[0].downcase
    case command

    when /^play-song$|^ps$/
      subcl.queue(arg, :song, {:play => true, :clear => true})
    when /^play-artist$|^pr$/
      subcl.queue(arg, :artist, {:play => true, :clear => true})
    when /^play-album$|^pl$/
      subcl.queue(arg, :album, {:play => true, :clear => true})
    when /^play-playlist$|^pp$/
      subcl.queue(arg, :playlist, {:play => true, :clear => true})
    when /^play-random$|^r$/
      subcl.queue(arg, :randomSong, {:play => true, :clear => true})
    when /^play-any$|^pn$|^p$/
      subcl.queue(arg, :any, {:play => true, :clear => true})
    when /^queue-next-song$|^ns$/
      subcl.queue(arg, :song, {:insert => true})
    when /^queue-next-artist$|^nr$/
      subcl.queue(arg, :artist, {:insert => true})
    when /^queue-next-album$|^nl$/
      subcl.queue(arg, :album, {:insert => true})
    when /^queue-next-playlist$|^np$/
      subcl.queue(arg, :playlist, {:insert => true})
    when /^queue-next-any$|^nn$|^n$/
      subcl.queue(arg, :any, {:insert => true})
    when /^queue-last-song$|^ls$/
      subcl.queue(arg, :song)
    when /^queue-last-artist$|^lr$/
      subcl.queue(arg, :artist)
    when /^queue-last-album$|^ll$/
      subcl.queue(arg, :album)
    when /^queue-last-playlist$|^lp$/
      subcl.queue(arg, :playlist)
    when /^queue-last-any$|^ln$|^l$/
      subcl.queue(arg, :any)
    when "albumart-url"
      arg = nil if arg.empty?
      @options[:out_stream].puts subcl.albumart_url(arg)
    when /^album-list$|^al$/
      subcl.albumlist
    when "test-notify"
      subcl.testNotify
    else
      begin
        #pass through for player commands
        subcl.send(command, [])
      rescue NoMethodError
        unknown(command)
      end
    end
  end

  def unknown(command)
    if @options[:tty] then
      @options[:err_stream].puts "Unknown command '#{command}'"
      @options[:err_stream].puts @usage
    else
      subcl.notifier.notify "Unknown command '#{command}'"
    end
    exit 3
  end
end
