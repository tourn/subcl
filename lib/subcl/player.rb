require 'ruby-mpd'
require 'delegate'

class Player < SimpleDelegator
  def initialize
    #TODO add configs for host/port/security
    @mpd = MPD.new
    begin
      @mpd.connect
    rescue
      raise SubclError.new('Could not connect to MPD! Is it running?')
    end
    super(@mpd)
  end

  #insert: whether to add the song after the currently playing one
  #instead of the end of the queue
  def add(song, insert = false)
    unless song[:stream_url]
      raise ArgumentError, "argument has no :stream_url!"
    end
    LOGGER.debug { "Adding #{song['title']}: #{song[:stream_url]}. Insert: #{insert}" }
    if insert then
      pos = @mpd.current_song.pos + 1
      @mpd.addid(song[:stream_url], pos)
    else
      @mpd.add(song[:stream_url])
    end
  end

  #stops the player and clears the playlist
  def clearstop
    @mpd.stop
    @mpd.clear
  end

  # if song has been playing for more than 4 seconds, rewind it to the start
  # otherwise go to the previous song
  def rewind
    if @mpd.status[:elapsed] > 4
      @mpd.seek 0
    else
      @mpd.previous
    end
  end

  # if mpd is playing, pause it. Otherwise resume playback
  def toggle
    if @mpd.playing?
      @mpd.pause = 1
    else
      # experimental hack: I think this forces mpd to start downloading the stream again.
      # this should prevent a bug that fails to resume streams after pausing
      # TODO might make this configurable
      @mpd.seek(@mpd.status[:elapsed].to_i)
      @mpd.pause = 0
    end
  end

  def pause
    @mpd.pause = 1
  end

  #TODO: might create a wrapper for current_song that makes API calls for artist, album, etc,
  # in case mpd is unable to decode the metadata
end
