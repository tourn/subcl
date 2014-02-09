require 'spec_helper'

describe Runner do
  before :each do
    @runner = Runner.new
  end

  it 'should display a test notification' do
    @runner.run ['test-notify']
  end
end
