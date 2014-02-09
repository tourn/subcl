require 'optparse'
require_relative 'subcl'

class Runner
  def initialize
    @options = { :tty => true }

    #TODO refactor this away
    if File.exist?('debug')
      puts "DEBUGGING"
      @options[:debug] = true
    end
  end

  def parse_options! args
    #no idea how to get this variable from outside, so we'll just set it in the loop
    usage = nil
    OptionParser.new do |opts|
      opts.banner = "Usage: subcl [options] command"
      opts.separator %{
    Commands
      list to terminal
          search[-song|-album|-artist] <pattern>
          ss|sl|sr <pattern>
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

    Options }

      usage = opts

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
        out_stream.puts opts
        exit
      end
      opts.on("--version", "Print version information") do
        out_stream.puts Configs.new.app_version
        exit
      end

    end.parse! args
  end

  def run(args, out_stream = STDOUT, err_stream = STDERR)
    @options[:out_stream]  = out_stream
    @options[:err_stream]  = err_stream
    parse_options!(args)

    unless args.size >= 1
      err_stream.puts usage
      exit 3
    end

    unless system('tty -s')
      #not running in a tty, so no use for interactivity
      @options[:tty] = false
      @options[:interactive] = false
    end

    subcl = Subcl.new @options

    arg = args[1,args.length-1].join(" ") #put rest of args together so no quotes are required

    case args[0].downcase

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
    when /^queue-next-song$|^ns$/
      subcl.queue(arg, :song, {:insert => true})
    when /^queue-next-artist$|^nr$/
      subcl.queue(arg, :artist, {:insert => true})
    when /^queue-next-album$|^nl$/
      subcl.queue(arg, :album, {:insert => true})
    when /^queue-next-playlist$|^np$/
      subcl.queue(arg, :playlist, {:insert => true})
    when /^queue-last-song$|^ls$/
      subcl.queue(arg, :song)
    when /^queue-last-artist$|^lr$/
      subcl.queue(arg, :artist)
    when /^queue-last-album$|^ll$/
      subcl.queue(arg, :album)
    when /^queue-last-playlist$|^lp$/
      subcl.queue(arg, :playlist)
    when /^search-song$|^ss$/
      subcl.searchSong(arg)
    when /^search-artist$|^sr$/
      subcl.searchArtist(arg)
    when /^search-album$|^sl$/
      subcl.searchAlbum(arg)
    when "albumart-url"
      arg = nil if arg.empty?
      out_stream.puts subcl.albumartUrl(arg)
    when /^album-list$|^al$/
      subcl.albumlist
    when "test-notify"
      subcl.testNotify
    else
      if @options[:tty] then
        err_stream.puts usage
      else
        subcl.notifier.notify "Unrecognized command"
      end
      exit 3
    end
  end
end
