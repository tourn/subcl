require 'spec_helper'

describe Subcl do
  it 'should display a list of albums' do
    subcl = Subcl.new
    subcl.albumlist
  end
end
