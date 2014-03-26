###
# This class interfaces with the subsonic API
# http://www.subsonic.org/pages/api.jsp
###

require 'net/http'
require 'rexml/document'
require 'thread' #Do I need this?
require 'cgi'
include REXML

class SubsonicAPI

  REQUIRED_SETTINGS = %i{server username password}

  def initialize(configs)
    @configs = {
      :appname => 'subcl',
      :app_version => '0.0.4',
      :proto_version => '1.9.0', #subsonic API protocol version
      :max_search_results => 20,
      :random_song_count => 10
    }.merge! configs.to_hash

    REQUIRED_SETTINGS.each do |setting|
      unless @configs.key? setting
        raise "Missing setting '#{setting}'"
      end
    end
  end

  #takes a list of albums or artists and returns a list of their songs
  def get_songs(entities)
    entities.collect_concat do |entity|
      case entity[:type]
      when :song
        entity
      when :album
        album_songs(entity[:id])
      when :artist
        artist_songs(entity[:id])
      when :playlist
        playlist_songs(entity[:id])
      else
        raise "Cannot get songs for '#{entity[:type]}'"
      end
    end
  end

  #returns an array of songs for the given album id
  def album_songs(id)
    doc = query('getAlbum.view', {:id => id})
    doc.elements.collect('subsonic-response/album/song') do |song|
      decorate_song(song.attributes)
    end
  end

  #returns an array of songs for the given artist id
  def artist_songs(id)
    doc = query('getArtist.view', {:id => id})
    doc.elements.inject('subsonic-response/artist/album', []) do |memo, album|
      memo += album_songs(album.attributes['id'])
    end
  end

  #returns all songs from playlist(s) matching the name
  def playlist_songs(id)
    doc = query('getPlaylist.view', {:id => id})
    doc.elements.collect('subsonic-response/playlist/entry') do |entry|
      decorate_song(entry.attributes)
    end
  end

  #returns all playlists
  def all_playlists
    doc = query('getPlaylists.view')
    doc.elements.collect('subsonic-response/playlists/playlist') do |playlist|
      {
        :id => playlist.attributes['id'],
        :name => playlist.attributes['name'],
        :owner => playlist.attributes['owner'],
        :type => :playlist
      }
    end
  end


  #returns all playlists matching name
  #subsonic features no mechanism to search by playlist name, so this method retrieves
  #all playlists and and filters them locally. This might become problematic when the server
  #has a huge amount of playlists
  def get_playlists(name)
    name.downcase!
    all_playlists().select do |playlist|
      playlist[:name].downcase.include? name
    end
  end

  #returns a list of albums from the specified type
  #http://www.subsonic.org/pages/api.jsp#getAlbumList2
  def albumlist(type = :random)
    #TODO might want to add validation for the type here
    doc = query('getAlbumList2.view', {:type => type})
    doc.elements.collect('subsonic-response/albumList2/album') do |album|
      album = album.attributes
      album = Hash[album.collect { |key,val| [key.to_sym, val] }]
      album[:type] = :album
      album
    end
  end

  def random_songs(count = @configs[:random_song_count])
    #throws an exception if its not parseable to an int
    count = Integer(count)

    doc = query('getRandomSongs.view', {:size => count})
    doc.elements.collect('subsonic-response/randomSongs/song') do |song|
      decorate_song(song.attributes)
    end
  end

  #takes the attributes of a song tag from the xml and applies the
  #:type and :stream_url attribute
  def decorate_song(attributes)
    attributes = Hash[attributes.collect {|key, val| [key.to_sym, val]}]
    attributes[:type] = :song
    attributes[:stream_url] = stream_url(attributes[:id])
    attributes
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
    when :playlist
      return get_playlists(query)
    when :any
      #XXX or do we now use max/3 for each?
      params[:songCount] = max
      params[:albumCount] = max
      params[:artistCount] = max
      #TODO need to search for playlists too!
    else
      raise "Cannot search for type '#{type}'"
    end

    doc = query('search3.view', params)

    results = %i{artist album song}.collect_concat do |entity_type|
      doc.elements.collect("subsonic-response/searchResult3/#{entity_type}") do |entity|
        entity = Hash[entity.attributes.collect{ |key, val| [key.to_sym, val]}]
        entity[:type] = entity_type
        if entity_type == :song
          entity[:stream_url] = stream_url(entity[:id])
          entity[:name] = entity[:title]
        end
        entity
      end
    end

    if type == :any
      results += get_playlists(query)
    end
    return results
  end

  def query(method, params = {})
    uri = build_url(method, params)
    LOGGER.debug { "query: #{uri} (basic auth sent per HTTP header)" }

    req = Net::HTTP::Get.new(uri.request_uri)
    req.basic_auth(@configs[:username], @configs[:password])
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
      return doc
    else
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
    params[:v] = @configs[:proto_version]
    params[:c] = @configs[:appname]
    query = params.collect {|k,v| "#{k}=#{URI.escape(v.to_s)}"}.join('&')

    URI("#{@configs[:server]}/rest/#{method}?#{query}")
  end

  #adds the basic auth parameters from the config to the URI
  def add_basic_auth(uri)
    uri.user = @configs[:username]
    uri.password = @configs[:password]
    return uri
  end

  #returns the streaming URL for the song, including basic auth
  def stream_url(songid)
    raise ArgumentError, "no songid!" unless songid
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

end
