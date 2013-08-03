require 'net/http'
require 'rexml/document'
require 'thread'
include REXML

require './configs'

class Subsonic
    
    def initialize
        begin
            @configs = Configs.new
        rescue => e
            puts e.message
            exit
        end
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

        searchResults = search(artist, "artist")

        if searchResults.length.zero?
            puts "No albums found by artist: " + artist
            return
        end

        aid = whichDidYouMean(searchResults) {|e| puts "#{e[0]} by #{e[1]}"}

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
        
        searchResults = search(album, "album")

        if searchResults.length.zero?
            puts "No albums found by artist: " + artist
            return
        end

        aid = whichDidYouMean(searchResults) {|e| puts "#{e[0]} by #{e[2]} (#{e[1]})"}

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
            #puts "[#{i}] #{value}"
            print "[#{i}] " 
            yield(value)
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

    def search(query, delim = nil)
        method = "search2.view"
        url = buildURL(method, "query", URI.escape(query))
        data = Net::HTTP.get_response(URI.parse(url)).body
        doc = Document.new(data)

        result_hash = {} # map to store results

        if delim.eql? "artist" or delim.eql? nil
            doc.elements.each('subsonic-response/searchResult2/artist') do |artist|
                result_hash[artist.attributes["id"]] = artist.attributes["name"]
            end
        end

        if delim.eql? "album" or delim.eql? nil
            doc.elements.each('subsonic-response/searchResult2/album') do |album|
                result_hash[album.attributes["id"]] = [album.attributes["title"],album.attributes["artist"]]
            end
        end

        if delim.eql? "song" or delim.eql? nil
            doc.elements.each('subsonic-response/searchResult2/song') do |song|
                result_hash[song.attributes["id"]] = [song.attributes["title"], song.attributes["album"], song.attributes["artist"]]
            end
        end

        result_hash
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

        url

    end

		#returns the streaming URL for the song
    def songUrl(songid)
        stream = "stream.view"
        buildURL(stream, "id", songid)
    end

    def queueAlbum(album, artist = "")

        searchResults = search(album, "album")

        if searchResults.length.zero? and not artist.eql? ""
            puts "No albums found by artist: " + artist
            return
        elsif searchResults.length.zero?
            puts album + ": album not found"
            return
        end
        
        aid = whichDidYouMean(searchResults) {|e| puts "#{e[0]} by #{e[1]}"}

        # method to get songs
        method = "getMusicDirectory.view"

        url = buildURL(method, "id", aid)

        data = Net::HTTP.get_response(URI.parse(url)).body

        doc = Document.new(data)

        doc.elements.each('subsonic-response/directory/child') do |song|
            enqueue(song.attributes["id"], song.attributes["title"])
        end
    end


    def showQueue
        tmpQueue = Queue.new

        until @queue.empty? do
            url = @queue.pop
            puts url
            tmpQueue << url
        end

        until tmpQueue.empty? do 
            url = tmpQueue.pop
            @queue << url
        end
    end

    def getSong(song, artist = "", album = "")
        searchResults = search(song, "song")

        if searchResults.length.zero?
            puts "Song not found: " + song
            return
        end
        
        return songUrl( whichDidYouMean(searchResults) {|e| puts "#{e[0]} by #{e[2]} (#{e[1]})"} )
        
    end

end
