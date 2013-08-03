require 'net/http'
require 'rexml/document'
require 'thread'
require 'cgi'
include REXML

require_relative 'configs'

class Subsonic

	def initialize
		begin
			@configs = Configs.new
		rescue => e
			puts e.message
			exit
		end
	end

	#returns a song streaming url for the given name
	#on multiple matches, the user is asked interactively for the wanted match
	def song(name)
		searchResults = search(name, :song)

		if searchResults.length.zero?
			puts "No matching song"
			return
		end

		return songUrl( whichDidYouMean(searchResults) {|e| puts "#{e[:title]} by #{e[:artist]} on #{e[:album]}"} )

	end

	#returns an array of song streaming urls for the given album name
	#on multiple matches, the user is asked interactively for the wanted match
	def albumSongs(album)

		searchResults = search(album, :album)

		if searchResults.length.zero?
			puts "No matching album"
			return
		end

		albumId = whichDidYouMean(searchResults) {|e| puts "#{e[:name]}"}

		songs = []
		doc = query('getMusicDirectory.view', {:id => albumId})
		doc.elements.each('subsonic-response/directory/child') do |song|
			songs << songUrl(song.attributes["id"])
		end

		songs
	end

	#returns an array of song streaming urls for the given artist name
	#on multiple matches, the user is asked interactively for the wanted match
	def artistSongs(name)
		searchResults = search(name, :artist)

		if searchResults.length.zero?
			puts "No matching artist"
			return
		end

		artistId = whichDidYouMean(searchResults) {|e| puts "#{e[:name]}"}

		songs = []
		doc = query('getArtist.view', {:id => artistId})
		doc.elements.each('subsonic-response/artist/album') do |album|
			doc = query('getAlbum.view', {:id => album.attributes['id']})
			doc.elements.each('subsonic-response/album/song') do |song|
				songs << songUrl(song.attributes["id"])
			end
		end

		songs
	end

	def whichDidYouMean(array)

		puts "wdym: #{array.size} elements"

		# only one value, return it
		return array.first[:id] if array.length == 1

		choices = {}
		i = 1

		array.each do |elem|
			choices[i] = elem
			print "[#{i}] " 
			yield(elem)
			i = i + 1
		end

		print "Which did you mean [1..#{i-1}]? "
		choice = $stdin.gets

		while choice.to_i < 1 or choice.to_i >= i do
			print "Bad choice. Try again. "
			choice = $stdin.gets
		end

		return choices[choice.to_i][:id]

	end

	#returns all artists matching the pattern
	def artists(name)
		search(name, :artist)
	end

	#returns all albums matching the pattern
	def albums
		search(name, :album)
	end

	#returns all songs matching the pattern
	def songs
		search(name, :song)
	end

	#returns the streaming URL for the song, including basic auth
	def songUrl(songid)
		uri = buildUrl('stream.view', {:id => songid})
		uri.user = @configs.uname
		uri.password = @configs.pword
		uri
	end

	#returns the albumart URL for the song
	def albumartUrl(streamUrl)
		raise ArgumentError if streamUrl.empty?
		id = CGI.parse(URI.parse(streamUrl).query)['id'][0]
		buildUrl('getCoverArt.view', {:id => id})
	end

	#should the need arise, this outputs the album art as binary
	def albumart
		puts "Not yet implemented"
	end

	private
		def search(query, type)
			out = []

			params = {
				:query => query, 
				:songCount => 0, 
				:albumCount => 0, 
				:artistCount => 0,
			}

			case type
			when :artist
				params[:artistCount] = @configs.max_search_results
			when :album
				params[:albumCount] = @configs.max_search_results
			when :song
				params[:songCount] = @configs.max_search_results
			when :any
				#XXX or do we now use max/3 for each?
				params[:songCount] = @configs.max_search_results
				params[:albumCount] = @configs.max_search_results
				params[:artistCount] = @configs.max_search_results
			end

			doc = query('search3.view', params)

			#read artists
			doc.elements.each('subsonic-response/searchResult3/artist') do |artist|
				out << {
					:id => artist.attributes["id"],
					:type => :artist,
					:name => artist.attributes["name"]
				}
			end

		#read albums
		doc.elements.each('subsonic-response/searchResult3/album') do |album|
			out << {
				:id => album.attributes["id"],
				:type => :album,
				:name => album.attributes["name"],
				:artist => album.attributes["artist"]
			}
		end

		#read songs
		doc.elements.each('subsonic-response/searchResult3/song') do |song|
			out << {
				:id => song.attributes["id"],
				:type => :song,
				:title => song.attributes["title"],
				:artist => song.attributes["artist"],
				:album => song.attributes["album"]
			}
		end

		out
		end

		def query(method, params)
			uri = buildUrl(method, params)
			req = Net::HTTP::Get.new(uri.request_uri)
			req.basic_auth(@configs.uname, @configs.pword)
			res = Net::HTTP.start(uri.hostname, uri.port) do |http|
				http.request(req)
			end
			Document.new(res.body)
		end

		def buildUrl(method, params)
			#params[:u] = @configs.uname
			#params[:p] = @configs.pword
			params[:v] = @configs.version
			params[:c] = @configs.appname
			query = params.map {|k,v| "#{k}=#{URI.escape(v.to_s)}"}.join('&')

			uri = URI("#{@configs.server}/rest/#{method}?#{query}")
			puts "url2: #{uri}"
			uri
		end

end
