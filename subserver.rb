require 'net/http'
require 'rexml/document'
include REXML

require 'configs'

class Subserver
    
    def initialize
        @configs = Configs.new
    end

    def getArtists
        # method to get the artists
        method = "getIndexes.view"

        url = buildURL(method)

        data = Net::HTTP.get_response(URI.parse(url)).body

        doc = Document.new(data)

        doc.elements.each('subsonic-response/indexes/index/artist') do |artist|
            puts artist.attributes["name"]
        end

    end

    def getAlbums(artist)

        searchResults = search(artist)

        result_hash = {}

        searchResults.elements.each('subsonic-response/searchResult2/artist') do |artist|
            result_hash[artist.attributes["id"]] = artist.attributes["name"]
        end

        if result_hash.length.zero?
            puts "No albums found by artist: " + artist
            return
        end

        aid = whichDidYouMean(result_hash)

        # method to grab albums
        method = "getMusicDirectory.view"

        url = buildURL(method, "id", aid)

        data = Net::HTTP.get_response(URI.parse(url)).body

        doc = Document.new(data)

        doc.elements.each('subsonic-response/directory/child') do |album|
            puts album.attributes["title"]
        end
        
    end

    def getSongs(album, artist = "")
        
        searchResults = search(album)

        result_hash = {}

        searchResults.elements.each('subsonic-response/searchResult2/album') do |album|
            unless artist.empty?
                if album.attributes["artist"].eql? artist
                    result_hash[album.attributes["id"]] = album.attributes["title"]
                end
            else
                result_hash[album.attributes["id"]] = album.attributes["title"]
            end
        end

        if result_hash.length.zero?
            puts "No albums found by artist: " + artist
            return
        end

        aid = whichDidYouMean(result_hash)

        # method to get songs
        method = "getMusicDirectory.view"

        url = buildURL(method, "id", aid)

        data = Net::HTTP.get_response(URI.parse(url)).body

        doc = Document.new(data)

        doc.elements.each('subsonic-response/directory/child') do |song|
            puts song.attributes["title"]
        end
    end

    def whichDidYouMean(hash)
        
        # only one value, return it
        if hash.length == 1
            hash.each_key { |key| return key }
        end

        hlocal = {}
        i = 1

        hash.each do |key, value|
            hlocal[i] = key
            puts "[#{i}] #{value}"
            i = i + 1
        end

        print "Which did you mean [1..#{i-1}]? "
        choice = gets

        while choice.to_i < 1 or choice.to_i >= i do
            print "Bad choice. Try again. "
            choice = gets
        end
        
        return hlocal[choice.to_i]

    end

    def search(query)
        method = "search2.view"

        url = buildURL(method, "query", URI.escape(query))

        data = Net::HTTP.get_response(URI.parse(url)).body

        return Document.new(data)

    end

    def buildURL(method, *params)

        if !(params.length % 2).zero?
            raise RangeError, "params must have an even number of values"
        end

        url = @configs.server + "/rest/" + method + "?u=" + @configs.uname + "&p=" + @configs.pword + "&v=" + @configs.version + "&c=" + @configs.appname

        # get the length of the variable array
        l = params.length

        for i in 0..(l/2 - 1) do
            # grab the key and value to add to the url string
            key = params[2 * i]
            value = params[2 * i + 1]

            # append them on the string
            url = url + "\&" + key + "=" + value
        end

        return url

    end

    def play(song, artist = "", album = "")

        searchResults = search(song)

        result_hash = {}

        searchResults.elements.each('subsonic-response/searchResult2/song') do |song|
            unless artist.empty?
                unless album.empty?
                    if song.attributes["artist"].eql? artist and song.attributes["album"].eql? album
                        result_hash[song.attributes["id"]] = song.attributes["title"]
                    end
                else
                    if song.attributes["artist"].eql? artist
                        result_hash[song.attributes["id"]] = song.attributes["title"]
                    end
                end
            else
                result_hash[song.attributes["id"]] = song.attributes["title"]
            end
        end

        if result_hash.length.zero?
            puts "Song not found: " + song
        end
        
        sid = whichDidYouMean(result_hash)
        
        method = "stream.view"

        url = buildURL(method, "id", sid)

        puts url

        system("mplayer \"#{url}\"")

        puts "Thanks!"
    end

end

subserver = Subserver.new
subserver.play("who are you")
#subserver.getSongs("the who")
# subserver.getSongs("all killer no filler")

