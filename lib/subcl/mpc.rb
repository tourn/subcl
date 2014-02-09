
class Mpc
  attr_accessor :debug

  def initialize
    @debug = false
  end

  def mpccall(cmd, quiet = true)
    call = "mpc #{cmd}"
    call << " > /dev/null" if quiet

    unless system(call)
      $stderr.puts "MPC call error: #{$?}"
    end

  end

  #insert: whether to add the song after the currently playing one
  #instead of the end of the queue
  def add(song, insert = false)
    unless song.respond_to? 'url'
      p song
      raise ArgumentError, "parameter does not have an #url method"
    end
    if @debug
      action = insert ? "insert" : "add"
      puts "would #{action} #{song['title']}: #{song.url}"
    else
      if insert then
        mpccall("insert '#{song.url}'")
      else
        mpccall("add '#{song.url}'")
      end
    end
  end

  def play
    if @debug
      puts "would play"
    else
      mpccall("play")
    end
  end

  #stops the player and clears the playlist
  def clear
    if @debug
      puts "would clear"
    else
      mpccall("stop")
      mpccall("clear")
    end
  end

  #returns info about the currently playing file
  def current(info = :url)
    filter =case info
    when :url
      '%file%'
    when :album
      '%album%'
    when :artist
      '%artist%'
    end
    `mpc --format '#{filter}' current`
  end
end
