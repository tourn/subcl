
require 'subserver'

class Subcl

    def initialize
        @ss = Subserver.new  
        repl
    end

    def repl
        puts "Subcl! Command-line Subsonic."
        #puts "Type 'help' for help"
        print "> "
        until (line = gets.chomp).eql? "quit"
            spl = line.split(' ')

            if spl[0].eql? "qs"
                song = ""
                # if we didn't get a value
                if spl.length == 1
                    print "[Song title]: "
                    song = gets.chomp
                else
                    song = spl[1,spl.length-1].join(' ')
                end

                # if we still didn't get a value
                unless song.eql? ""
                    @ss.queueSong(song)
                end
            elsif spl[0].eql? "qa"
                album = ""
                # if we didn't get a value
                if spl.length == 1
                    print "[Album title]: "
                        album = gets.chomp
                else
                    album = spl[1,spl.length-1].join(' ')
                end

                # if we still didn't get a value
                unless album.eql? ""
                    @ss.queueAlbum(album)
                end
            elsif spl[0].eql? "artists"
                @ss.getArtists
            elsif spl[0].eql? "play"
                @ss.play
            elsif spl[0] != "quit"
                puts "#{spl[0]}: command unrecognized"
            end
            
            if spl[0] != "quit"
                print "> "
            end
        end
        puts "Bye!"
    end
end

subcl = Subcl.new

=begin
subserver = Subserver.new

puts "Subcl! Command-line Subsonic."
puts "Type 'help' for help"
print "> "
until (line = gets.chomp).eql? "quit"
    spl = line.split(' ')

    if spl[0].eql? "qs"
        song = ""
        # if we didn't get a value
        if spl.length == 1
            print "[Song title]: "
            song = gets
        else
            song = spl.index[1,spl.length-1].join(' ')
        end

        # if we still didn't get a value
        unless song.eql? "\n"
            subserver.queueSong(song)
        end
    elsif spl[0].eql? "qa"
        album = ""
        # if we didn't get a value
        if spl.length == 1
            print "[Album title]: "
            album = gets
        else
            album = spl.index[1,spl.length-1].join(' ')
        end

        # if we still didn't get a value
        unless album.eql? ""
            subserver.queueAlbum(album)
        end
    elsif spl[0].eql? "artists"
        subserver.getArtists
    elsif spl[0].eql? "play"
        subserver.play
    elsif spl[0] != "quit"
        puts "#{spl[0]}: command unrecognized"
    end

    if spl[0] != "quit"
        print "> "
    end
end
puts "Bye!"
=end
