require 'rake'
require 'time'

Gem::Specification.new do |s|
	s.name = 'subcl'
	s.version = '1.1.1'
	s.date = DateTime.now.strftime('%Y-%m-%d')
	s.summary = 'A commandline client for the subsonic music server'
	s.description = %Q{ This is a commandline client for the subsonic music server (www.subsonic.org) relying on mpd for playback. It supports searching for songs, albums, etc on the commandline and adding them to mpds playlist. It also brings some commands to control the playback.}
	s.author = 'Daniel Latzer'
	s.email = 'latzer.daniel@gmail.com'
	s.files = FileList['lib/**/*', 'bin/*', 'share/*'].to_a
	s.executables << 'subcl'
	s.executables << 'subcl-api'
	s.platform = Gem::Platform::RUBY
	s.homepage = 'https://github.com/Tourniquet/subcl'
	s.required_ruby_version = '>= 2.0.0'
	s.licenses = ['MIT']
  s.add_development_dependency 'rspec', '=2.14.1'
  s.add_runtime_dependency 'ruby-mpd', '=0.3.1'
  s.requirements << 'mpd'
end

