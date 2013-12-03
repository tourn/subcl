require 'rake'

Gem::Specification.new do |s|
	s.name = "subcl"
	s.version ="1.0.1"
	s.date = "2013-12-03"
	s.summary = "A commandline client for the subsonic music server"
	s.description = %Q{ This is a commandline client for the subsonic music server (www.subsonic.org). It relies on mpd and mpc. }
	s.authors = ["Daniel Latzer"]
	s.email = 'latzer.daniel@gmail.com'
	s.files = FileList['lib/*', 'bin/*', 'share/icon.png'].to_a
	s.executables << 'subcl'
	s.platform = Gem::Platform::RUBY
	s.homepage = 'https://github.com/Tourniquet/subcl'
	s.required_ruby_version = '>= 1.9.2'
end

