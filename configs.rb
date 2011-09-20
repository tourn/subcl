
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
            end
        end

        if @server == nil or @uname == nil or @pword == nil
            raise "Incorrect configuration file"
        end

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

    def server
        @server
    end

    def uname
        @uname
    end

    def pword
        @pword
    end

    def version
        @version
    end

    def appname
        @appname
    end
end
