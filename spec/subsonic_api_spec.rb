require 'spec_helper'

describe SubsonicAPI do
  def doc(file)
    prefix = 'spec/responses/'
    Document.new(open(prefix + file))
  end

  it 'should return a list of songs for the search of songs' do
    query = 'ephemeral'
    api = SubsonicAPI.new({:max_search_results => 100})
    api.should_receive(:query).with('search3.view', anything()).and_return(doc('songs_search.xml'))
    re = api.songs(query)
    p re
    re.length.should == 1
  end

  it 'should return a list of songs for the search of albums' do
    query = 'intervals'
    api = SubsonicAPI.new({:max_search_results => 100})
    api.should_receive(:query).with('search3.view', anything()).and_return(doc('album_songs_search.xml'))
    api.should_receive(:query).with('getAlbum.view', anything()).and_return(doc('getAlbum-1.xml'))
    api.should_receive(:query).with('getAlbum.view', anything()).and_return(doc('getAlbum-2.xml'))
    api.album_songs(query).length.should == 10
  end
end
