require 'subcl/configs'
require 'subcl/player'
require 'subcl/notify'
require 'subcl/picker'
require 'subcl/runner'
require 'subcl/song'
require 'subcl/subcl'
require 'subcl/subcl_error'
require 'subcl/subsonic_api'

require 'logger'

LOGGER = Logger.new(STDERR)
LOGGER.level = Logger::INFO
