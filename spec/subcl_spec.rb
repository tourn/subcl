require 'spec_helper'
require 'stringio'

describe Subcl do
  before :each do
    @out = StringIO.new
    @err = StringIO.new
    @subcl = Subcl.new({
      :out_stream => @out,
      :err_stream => @err
    })
  end

  it 'should display a list of albums' do
    api = double()
    api.should_receive(:albumlist).with().and_return(
      [ { :name => 'bar', :artist => 'the foos', :year => 2000 },
        { :name => 'baz', :artist => 'the foos', :year => 2004 }]
    )
    @subcl.api = api

    @subcl.albumlist

    @out.string.should include('bar')
    @out.string.should include('baz')
  end
end
