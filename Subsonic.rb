require 'net/http'
require 'rexml/document'
require 'thread'
require 'cgi'
include REXML

require_relative 'configs'
require_relative 'Song'

class Subsonic

	attr_accessor :interactive

	def initialize
		begin
			@configs = Configs.new
		rescue => e
			$stderr.puts e.message
			exit
		end

		@interactive = true
	end

	#returns an array of songs for the given album name
	#on multiple matches, the user is asked interactively for the wanted match
	def song(name)
		searchResults = search(name, :song)

		if searchResults.length.zero?
			$stderr.puts "No matching song"
			return []
		end

		return whichDidYouMean(searchResults) {|e| $stderr.puts "#{e[:title]} by #{e[:artist]} on #{e[:album]}"}

	end

	#returns an array of songs for the given album name
	#on multiple matches, the user is asked interactively for the wanted match
	def albumSongs(name)

		searchResults = search(name, :album)

		if searchResults.length.zero?
			$stderr.puts "No matching album"
			return []
		end

		picks = whichDidYouMean(searchResults) {|e| $stderr.puts "#{e[:name]} by #{e[:artist]}"}
		songs = []
		picks.each do |album|
			doc = query('getAlbum.view', {:id => album['id']})
			doc.elements.each('subsonic-response/album/song') do |attributes|
				songs << Song.new(self, attributes)
			end
		end

		songs
	end

	#returns an array of song streaming urls for the given artist name
	#on multiple matches, the user is asked interactively for the wanted match
	def artistSongs(name)
		searchResults = search(name, :artist)

		if searchResults.length.zero?
			$stderr.puts "No matching artist"
			return []
		end

		picks = whichDidYouMean(searchResults) {|e| $stderr.puts "#{e[:name]}"}
		songs = []
		picks.each do |artist|
			doc = query('getArtist.view', {:id => artist['id']})
			doc.elements.each('subsonic-response/artist/album') do |album|
				doc = query('getAlbum.view', {:id => album.attributes['id']})
				doc.elements.each('subsonic-response/album/song') do |attributes|
					songs << Song.new(self, attributes)
				end
			end
		end

		songs
	end

	def whichDidYouMean(array)

		if array.length == 1 or !@interactive
			return array
		end

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

		#TODO awesome choice parsing here
		picks = []
		while choice.to_i < 1 or choice.to_i >= i do
			print "Bad choice. Try again. "
			choice = $stdin.gets
		end
		picks << choices[choice.to_i]

		return picks

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

	#returns the streaming URL for the song, including basic auth
	def songUrl(songid)
		uri = buildUrl('stream.view', {:id => songid})
		addBasicAuth(uri)
	end

	#returns the albumart URL for the song
	def albumartUrl(streamUrl)
		raise ArgumentError if streamUrl.empty?
		id = CGI.parse(URI.parse(streamUrl).query)['id'][0]
		addBasicAuth(
			buildUrl('getCoverArt.view', {:id => id})
		)
	end

	#should the need arise, this outputs the album art as binary
	def albumart
		$stderr.puts "Not yet implemented"
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

			#TODO find proper variable names. seriously.
			['artist','album','song'].each do |entityName|
				doc.elements.each("subsonic-response/searchResult3/#{entityName}") do |entity|
					ob = nil
					if entityName == 'song'
						ob = Song.new self, entity.attributes
					else
						ob = entity.attributes
						ob['type'] = entityName
					end
					out << ob
				end
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

			doc = Document.new(res.body)

			#handle error response
			doc.elements.each('subsonic-response/error') do |error|
				$stderr.puts "query: #{uri} (basic auth sent per HTTP header)"
				$stderr.print "Error communicating with the Subsonic server: "
				$stderr.puts  "#{error.attributes["message"]} (#{error.attributes["code"]})"
				exit 1
			end

			#handle http error
			case res.code
			when '200'
				doc
			else
				$stderr.puts "query: #{uri} (basic auth sent per HTTP header)"
				$stderr.print "Error communicating with the Subsonic server: "
				case res.code
				when '401'
					$stderr.puts "HTTP 401. Might be an incorrect username/password"
				else
					$stderr.puts "HTTP #{res.code}"
				end
				exit 1
			end
		end

		def buildUrl(method, params)
			#params[:u] = @configs.uname
			#params[:p] = @configs.pword
			params[:v] = @configs.proto_version
			params[:c] = @configs.appname
			query = params.map {|k,v| "#{k}=#{URI.escape(v.to_s)}"}.join('&')

			uri = URI("#{@configs.server}/rest/#{method}?#{query}")
			#puts "url2: #{uri}"
			uri
		end

		#adds the basic auth parameters from the config to the URI
		def addBasicAuth(uri)
			uri.user = @configs.uname
			uri.password = @configs.pword
			return uri
		end

end
