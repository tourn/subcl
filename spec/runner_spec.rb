require 'spec_helper'
require 'stringio'
require 'rspec/expectations'

describe Runner do
  def doc(file)
    prefix = 'spec/responses/'
    Document.new(open(prefix + file))
  end

  before :each do
    @out = StringIO.new
    @err = StringIO.new
    @api = SubsonicAPI.new({
      :server => 'example.com',
      :username => 'foo',
      :password => 'bar'
    })
    @player = double("Player")
    @runner = Runner.new({
      :out_stream => @out,
      :err_stream => @err,
      :mock_api => @api,
      :mock_player => @player
    })
  end

  it 'should display a test notification' do
    @runner.run ['test-notify']
  end

  describe 'play|queue' do
    context 'when finding a unique song' do
      before :each do
        @api.should_receive(:query) do |method, args|
          method.should == 'search3.view'
          args[:query].should == 'ephemeral'
        end.and_return(doc('songs_search.xml'))
      end

      it 'should play a song' do
        @player.should_receive(:clear).once
        @player.should_receive(:add).once
        @player.should_receive(:play).once
        @runner.run %w{play-song ephemeral}
      end

      it 'should queue a song last' do
        @player.should_receive(:add).once
        @runner.run %w{queue-last-song ephemeral}
      end

      it 'should queue a song next' do
        @player.should_receive(:add).with(anything(), true).once
        @runner.run %w{queue-next-song ephemeral}
      end
    end

    context 'when finding multiple songs' do
      before :each do
        @api.should_receive(:query) do |method, args|
          method.should == 'search3.view'
          args[:query].should == 'pain'
        end.and_return(doc('songs_search_multi.xml'))
      end

      context 'using the --use-first flag' do
        it 'should only pick the first with the --use-first flag' do
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=5356/
          end.once
          @runner.run %w{queue-next-song --use-first pain}
        end
      end

      context 'running interactively' do
        it 'should let me choose the first song' do
          STDIN.should_receive(:gets).and_return("1");
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=5356/
          end.once
          @runner.run %w{queue-next-song pain}
        end

        it 'should let me choose the first song' do
          STDIN.should_receive(:gets).and_return("2");
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=5812/
          end.once
          @runner.run %w{queue-next-song pain}
        end

        it 'should let me choose song 1 and 3' do
          STDIN.should_receive(:gets).and_return("1,3");
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=5356/
          end
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=9313/
          end
          @runner.run %w{queue-next-song pain}
        end

        it 'should let me choose song 1 to 3' do
          STDIN.should_receive(:gets).and_return("1-3");
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=5356/
          end
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=5812/
          end.once
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=9313/
          end
          @runner.run %w{queue-next-song pain}
        end

        it 'should let me choose all the songs' do
          STDIN.should_receive(:gets).and_return("all");
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=5356/
          end
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=5812/
          end.once
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=9313/
          end
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=9446/
          end
          @player.should_receive(:add) do |song|
            song[:stream_url].to_s.should =~ /id=6087/
          end
          @runner.run %w{queue-next-song pain}
        end
      end
    end

    context 'playing an album' do
    end

    context 'playing an artist' do
    end

    context 'playing a playlist' do
    end
  end

  describe 'albumart_url' do
    it 'should return the url for the albumart of the currently playing song' do
      stream_url = "http://example.com/rest/stream.view?id=5584&v=1.9.0&c=subcl"
      @player.should_receive(:current).and_return(stream_url)
      @out.should_receive(:puts) do |url|
        url.to_s.should match(%r#foo:bar@example\.com/rest/getCoverArt\.view\?id=5584#)
      end
      @runner.run %w{albumart-url}
    end
  end

  describe 'search' do
    it 'should search for songs' do
    end

    it 'should search for albums' do
    end

    it 'should search for artists' do
    end

    it 'should search for playlists' do
    end
  end
end
