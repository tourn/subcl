
class Configs

    def initialize
        @filename = File.expand_path("~/.subcl")
        unless File.file?(@filename)
            raise "Config file not found"
        end
    
        readConfigs

        # our appname
        @appname = "subcl"

        getVersion
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
                @pword = spl[1]
            end
        end

        if @server == nil or @uname == nil or @pword == nil
            raise "Incorrect configuration file"
        end

				@max_search_results = 50 if @max_search_results == nil

    end

    def getVersion
        url = @server + "/rest/ping.view"
        begin
            data = Net::HTTP.get_response(URI.parse(url)).body
        rescue
            raise "Couldn't connect to server: #{@server}"
        end
        doc = Document.new(data)
        doc.elements.each('subsonic-response') do |response|
            @version = response.attributes["version"]
        end

        if @version.eql? "" or @version == nil
            raise "Invalid version response from server: #{@server}"
        end
    end

		attr_reader :server
		attr_reader :uname
		attr_reader :pword
		attr_reader :version
		attr_reader :max_search_results
		attr_reader :appname

end
