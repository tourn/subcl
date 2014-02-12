class Configs

  attr_accessor :configs

  REQUIRED_SETTINGS = %i{ server username password }
  OPTIONAL_SETTINGS = %i{ max_search_results notify_method random_song_count }

  def initialize(file = '~/.subcl')
    @configs = {
      #TOOD appversion is kinda weird here. put it somewhere where the gemspec can reach it too
      :notifyMethod => "auto",
    }

    @filename = File.expand_path(file)
    unless File.file?(@filename)
      raise "Config file not found"
    end

    read_configs
  end

  def read_configs
    settings = REQUIRED_SETTINGS + OPTIONAL_SETTINGS
    open(@filename).each_line do |line|
      next if line.start_with? '#'

      key, value = line.split(' ')
      key = key.to_sym
      if settings.include? key
        @configs[key] = value
      else
        LOGGER.warn { "Unknown setting: '#{key}'" }
      end
    end

    REQUIRED_SETTINGS.each do |setting|
      if @configs[setting].nil?
        raise "Missing setting '#{setting}'"
      end
    end
  end

  def [](key)
    raise "Undefined setting #{key}" unless @configs.has_key? key
    @configs[key]
  end

  def []=(key, val)
    settings = REQUIRED_SETTINGS + OPTIONAL_SETTINGS
    settings.each do |name|
      if key == name
        @configs[key] = val
        return
      end
    end
    raise "Undefined setting #{key}"
  end

  def to_hash
    @configs
  end
end
