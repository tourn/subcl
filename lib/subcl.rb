require 'subcl/version'

require 'subcl/configs'
require 'subcl/player'
require 'subcl/notify'
require 'subcl/picker'
require 'subcl/runner'
require 'subcl/song'
require 'subcl/subcl'
require 'subcl/subsonic_api'

require 'subcl/subcl_error'

require 'logger'

LOGGER = Logger.new(STDERR)
LOGGER.level = Logger::INFO
