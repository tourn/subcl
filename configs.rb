class Configs

	attr_reader :server
	attr_reader :uname
	attr_reader :pword
	attr_reader :proto_version
	attr_reader :max_search_results
	attr_reader :appname
	attr_reader :app_version

	def initialize
		@app_version = '1.0'
		#subsonic API protocol version
		@proto_version = '1.9.0'
		@appname = 'subcl'
		@max_search_results = 20 #default value

		@filename = File.expand_path("~/.subcl")
		unless File.file?(@filename)
			raise "Config file not found"
		end

		readConfigs
		ping
	end

	def readConfigs

		file = File.new(@filename, "r")
		while (line = file.gets) do
			spl = line.split(' ')
			if spl[0].eql? "server"
				@server = spl[1]
			elsif spl[0].eql? "username"
				@uname = spl[1]
			elsif spl[0].eql? "password"
				@pword = spl[1]
			elsif spl[0].eql? "max_search_results"
				@max_search_results = spl[1]
			end
		end

		if @server == nil or @uname == nil or @pword == nil
			raise "Incorrect configuration file"
		end
	end

	#check to see if the server is reachable
	def ping
		url = @server + "/rest/ping.view"
		begin
			Net::HTTP.get_response(URI.parse(url))
		rescue
			raise "Couldn't connect to server: #{@server}"
		end
	end

end
