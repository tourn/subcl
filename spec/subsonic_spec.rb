require 'spec_helper'

describe Subsonic do
	it 'should initialize without crashing' do
		Subsonic.new(nil, nil)
	end
end
