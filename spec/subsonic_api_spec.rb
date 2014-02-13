require 'spec_helper'

describe SubsonicAPI do
  def doc(file)
    prefix = 'spec/responses/'
    Document.new(open(prefix + file))
  end

  before :each do
    @default_configs = {
      :max_search_results => 100,
      :server => 'http://example.com',
      :username => 'username',
      :password => 'password',
      :proto_version => '1.9.0',
      :appname => 'subcl-spec'
    }

    @api = SubsonicAPI.new(@default_configs)
  end

  describe '#search' do
    it 'should return some songs with stream url' do
      @api.should_receive(:query).with('search3.view', anything()).and_return(doc('songs_search.xml'))
      re = @api.search('foo',:song) #the query result is mocked anyway
      re.length.should == 1
      url = re.first[:stream_url]
      url.to_s.should == 'http://username:password@example.com/rest/stream.view?id=11048&v=1.9.0&c=subcl-spec'
    end

    it 'should return some albums' do
      @api.should_receive(:query).with('search3.view', anything()).and_return(doc('album_search.xml'))
      re = @api.search('foo', :album)
      re.length.should == 2
      re.first[:id].should == '473'
      re[1][:id].should == '474'
    end

    it 'should return some artists' do
      @api.should_receive(:query).with('search3.view', anything()).and_return(doc('artist_search.xml'))
      re = @api.search('foo', :artist)
      re.length.should == 2
      re.first[:id].should == '38'
      re[1][:id].should == '39'
    end

    it 'should return anything that matches' do
      @api.should_receive(:query).with('search3.view', anything()).and_return(doc('any_search.xml'))
      re = @api.search('foo', :any)
      re.length.should == 3
      artist = re[0]
      artist[:type].should == :artist
      artist[:id].should == '45'
      album = re[1]
      album[:type].should == :album
      album[:id].should == '128'
      song = re[2]
      song[:type].should == :song
      song[:id].should == '1577'
    end

    it 'should return some playlists' do
      name = 'peripherial'
      @api.should_receive(:query).with('getPlaylists.view').and_return(doc('getPlaylists.xml'))
      re = @api.search(name, :playlist)
      re.length.should == 1
      re.first[:name].downcase.should == name
    end
  end

  describe '#random_songs' do
    it 'should return some random songs with default count' do
      default_count = 10 #set in subsonicAPI
      @api.should_receive(:query) do |path, args|
        path.should == 'getRandomSongs.view'
        p args
        args[:size].should == default_count
      end.and_return(doc('random.xml'))

      re = @api.random_songs
      re.length.should == default_count

      #TODO test one song to be properly formatted
    end

    it 'should return some random songs with explicit count' do
      count = 15
      api = SubsonicAPI.new(@default_configs.merge({:random_song_count => count}))
      api.should_receive(:query) do |path, args|
        path.should == 'getRandomSongs.view'
        args[:size].should == count
      end.and_return(doc('random-15.xml'))

      re = api.random_songs(count)
      re.length.should == count

      #TODO test one song to be properly formatted
    end
  end

  describe '#get_songs' do
    it 'should return a list of songs the way they are' do
      songs = [
        { :type => :song, :id => 1 },
        { :type => :song, :id => 2 }
      ]
      re = @api.get_songs(songs)
      re.should == songs
    end

    it 'should retrieve the songs for some albums' do
      albums = [
        { :type => :album, :id => 1 },
        { :type => :album, :id => 2 }
      ]
      @api.should_receive(:album_songs).twice.and_call_original
      @api.should_receive(:query) do |path, args|
        path.should == 'getAlbum.view'
        args[:id].should == 1
      end.and_return(doc('getAlbum-1.xml'))
      @api.should_receive(:query) do |path, args|
        path.should == 'getAlbum.view'
        args[:id].should == 2
      end.and_return(doc('getAlbum-2.xml'))

      re = @api.get_songs(albums)

      re.length.should == 10
    end

    it 'should retrieve the songs for some artist' do
      artist = [ { :type => :artist, :id => 1 } ]
      @api.should_receive(:artist_songs).once.with(1).and_call_original
      @api.should_receive(:album_songs).with("473").and_return([{:type => :song, :id => 1}])
      @api.should_receive(:album_songs).with("474").and_return([{:type => :song, :id => 2}])
      @api.should_receive(:query) do |path, args|
        path.should == 'getArtist.view'
        args[:id].should == 1
      end.and_return(doc('getArtist.xml'))

      re = @api.get_songs(artist)
      re.should == [
        {:type => :song, :id => 1},
        {:type => :song, :id => 2}
      ]
    end

    it 'should retrieve the songs for some playlist' do
      playlist = [ { :type => :playlist, :id => 3 } ]
      @api.should_receive(:playlist_songs).once.with(3).and_call_original
      @api.should_receive(:query) do |path, args|
        path.should == 'getPlaylist.view'
        args[:id].should == 3
      end.and_return(doc('getPlaylist.xml'))

      re = @api.get_songs(playlist)
      re.length.should == 5
    end
  end

  describe '#all_playlists' do
    it 'should return a list of all playlists' do
      @api.should_receive(:query).with('getPlaylists.view').and_return(doc('getPlaylists.xml'))
      re = @api.all_playlists
      re.length.should == 2
      re.each do |playlist|
        playlist[:type].should == :playlist
      end
    end
  end
end
