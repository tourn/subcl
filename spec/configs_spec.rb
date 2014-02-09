require 'spec_helper'


describe Configs do
  it 'should raise an error if config is not found' do
    expect { Configs.new('spec/configs/not_there') }.to raise_error
  end

  it 'should raise an error if config is incomplete' do
    expect { Configs.new('spec/configs/incomplete') }.to raise_error
  end

  it 'should work fine when all options are given' do
    Configs.new('spec/configs/complete').stub(:ping)
  end

  it 'should give a warning when unknown options are found' do
    logger = double()
    logger.should_receive(:warn)
    stub_const("LOGGER",  logger)
    Configs.new('spec/configs/invalid').stub(:ping)
  end
end
