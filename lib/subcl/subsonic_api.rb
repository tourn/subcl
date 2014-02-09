###
# This class interfaces with the subsonic API
# http://www.subsonic.org/pages/api.jsp
###

require 'net/http'
require 'rexml/document'
require 'thread' #Do I need this?
require 'cgi'
include REXML

#TODO move picker invocation up to Subcl; this class should only handle API calls
class SubsonicAPI

  def initialize(configs)
    @configs = configs
  end

  #returns an array of songs for the given song name
  def song(name)
    search(name, :song)
  end

  #return an array of albums matching the given name
  def albums(name)
    search(name, :album)
  end

  #TODO make something to get songs from a list of albums/artists

  #returns an array of songs for the given album name
  def album_songs(name)
    searchResults = search(name, :album)

    searchResults.collect_concat do |album|
      doc = query('getAlbum.view', {:id => album['id']})
      doc.elements.collect('subsonic-response/album/song') do |songEntry|
        song = songEntry.attributes
        song[:stream_url] = nil #TODO
        song
      end
    end
  end

  #returns an array of song streaming urls for the given artist name
  #on multiple matches, the user is asked interactively for the wanted match
  def artist_songs(name)
    searchResults = search(name, :artist)

    if searchResults.length.zero?
      return []
    end

    picks = invoke_picker(searchResults, &@display[:artist])
    songs = []
    picks.each do |artist|
      doc = query('getArtist.view', {:id => artist['id']})
      doc.elements.each('subsonic-response/artist/album') do |album|
        doc = query('getAlbum.view', {:id => album.attributes['id']})
        doc.elements.each('subsonic-response/album/song') do |element|
          songs << Song.new(self, element.attributes)
        end
      end
    end

    songs
  end

  def invoke_picker(array, &displayProc)
    if array.empty? or array.length == 1
      return array
    end

    if !@interactive
      return [array.first]
    end

    return Picker.new(array).pick(&displayProc)

  end

  #returns all artists matching the pattern
  def artists(name)
    search(name, :artist)
  end

  #returns all albums matching the pattern
  def albums(name)
    search(name, :album)
  end

  #returns all songs matching the pattern
  def songs(name)
    search(name, :song)
  end

  #returns all playlists
  def all_playlists
    out = []
    doc = query('getPlaylists.view')
    doc.elements.each('subsonic-response/playlists/playlist') do |playlist|
      item = {
        :id => playlist.attributes['id'],
        :name => playlist.attributes['name'],
        :owner => playlist.attributes['owner']
      }
      out << item
    end
    out
  end


  #returns all playlists matching name
  def playlists(name = nil)
    all = all_playlists
    out = []

    if name
      name.downcase!
      all.each do |playlist|
        if playlist[:name].downcase.include? name
          out << playlist
        end
      end
    end

    invoke_picker(out, &@display[:playlist])
  end

  #returns all songs from playlist(s) matching the name
  def playlist_songs(playListName)
    out = []
    playlists(playListName).each do |playlist|
      doc = query('getPlaylist.view', {:id => playlist[:id]})
      doc.elements.each('subsonic-response/playlist/entry') do |entry|
        out << Song.new(self, entry.attributes)
      end
    end
    out
  end

  #returns the streaming URL for the song, including basic auth
  def song_url(songid)
    uri = build_url('stream.view', {:id => songid})
    add_basic_auth(uri)
  end

  #returns the albumart URL for the song
  def albumart_url(streamUrl, size = nil)
    raise ArgumentError if streamUrl.empty?
    id = CGI.parse(URI.parse(streamUrl).query)['id'][0]
    params = {:id => id};
    params[:size] = size unless size.nil?
    add_basic_auth(
      build_url('getCoverArt.view', params)
    )
  end

  def albumlist
    doc = query('getAlbumList2.view', {:type => 'random'})
    #there must be a cleaner way to do this
    out = []
    doc.elements.each('subsonic-response/albumList2/album') do |album|
      out << album.attributes
    end
    return out
  end

  def random_songs(count)
    if count.empty?
      count = @configs.randomSongCount
    else
      #throw an exception if it's not an int
      count = Integer(count)
    end
    out = []
    doc = query('getRandomSongs.view', {:size => count})
    doc.elements.each('subsonic-response/random_songs/song') do |song|
      out << Song.new(self, song.attributes)
    end
    out
  end

  def search(query, type)
    params = {
      :query => query,
      :songCount => 0,
      :albumCount => 0,
      :artistCount => 0,
    }

    max = @configs[:max_search_results]
    case type
    when :artist
      params[:artistCount] = max
    when :album
      params[:albumCount] = max
    when :song
      params[:songCount] = max
    when :any
      #XXX or do we now use max/3 for each?
      params[:songCount] = max
      params[:albumCount] = max
      params[:artistCount] = max
    end

    doc = query('search3.view', params)

    #TODO find proper variable names. seriously.
    ['artist','album','song'].collect_concat do |entityName|
      doc.elements.collect("subsonic-response/searchResult3/#{entityName}") do |entity|
        if entityName == 'song'
          song = entity.attributes
          song['type'] = :song
          song
        else
          out = entity.attributes
          out['type'] = entityName
          out
        end
      end
    end
  end

  def query(method, params = {})
    uri = build_url(method, params)
    LOGGER.debug "query: #{uri} (basic auth sent per HTTP header)"

    req = Net::HTTP::Get.new(uri.request_uri)
    req.basic_auth(@configs.uname, @configs.pword)
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    doc = Document.new(res.body)

    LOGGER.debug { "response: " + doc.to_s }

    #handle error response
    doc.elements.each('subsonic-response/error') do |error|
      raise SubclError, "#{error.attributes["message"]} (#{error.attributes["code"]})"
    end

    #handle http error
    case res.code
    when '200'
      doc
    else
      #TODO make the next line conditional for debug/verbose mode
      $stderr.puts "query: #{uri} (basic auth sent per HTTP header)"
      msg = case res.code
      when '401'
        "HTTP 401. Might be an incorrect username/password"
      else
        "HTTP #{res.code}"
      end
      raise SubclError, msg
    end
  end

  def build_url(method, params)
    #params[:u] = @configs.uname
    #params[:p] = @configs.pword
    params[:v] = @configs.proto_version
    params[:c] = @configs.appname
    query = params.map {|k,v| "#{k}=#{URI.escape(v.to_s)}"}.join('&')

    uri = URI("#{@configs.server}/rest/#{method}?#{query}")
    uri
  end

  #adds the basic auth parameters from the config to the URI
  def add_basic_auth(uri)
    uri.user = @configs.uname
    uri.password = @configs.pword
    return uri
  end

end
