require 'fileutils'

class Configs

  attr_accessor :configs

  REQUIRED_SETTINGS = %i{ server username password }
  OPTIONAL_SETTINGS = %i{ max_search_results notify_method random_song_count wildcard_order}
  DEFAULT_PATH = File.expand_path('~/.subcl')
  DEFAULT_CONFIG = File.dirname(__FILE__) + "/../../share/subcl.default"

  WILDCARD_ORDER_ITEMS = %i{ song album artist playlist }

  def initialize(file = DEFAULT_PATH)
    @configs = {
      :notifyMethod => "auto",
    }

    @file = File.expand_path(file)
    unless File.file?(@file)
      if @file == DEFAULT_PATH and Configs.tty?
        ask_create_config
      else
        raise "Config file '#{@file}' not found"
      end
    end

    read_configs
  end

  def read_configs
    settings = REQUIRED_SETTINGS + OPTIONAL_SETTINGS
    open(@file).each_line do |line|
      next if line.start_with? '#'
      next if line.chomp.empty?

      key, value = line.split(' ', 2)
      value.chomp!

      key = key.to_sym
      if settings.include? key
        @configs[key] = value
      else
        LOGGER.warn { "Unknown setting: '#{key}'" }
      end
    end

    validate_wildcard_order

    REQUIRED_SETTINGS.each do |setting|
      if @configs[setting].nil?
        raise "Missing setting '#{setting}'"
      end
    end
  end

  def validate_wildcard_order
    if @configs[:wildcard_order]
      raw_order = @configs[:wildcard_order]
      final_order = []
      raw_order.split(',').each do |item|
        item = item.to_sym
        if WILDCARD_ORDER_ITEMS.include? item
          final_order << item
        else
          LOGGER.warn("Invalid wildcard_order item #{item}")
        end
      end

      WILDCARD_ORDER_ITEMS.each do |item|
        unless final_order.include? item
          LOGGER.warn("wildcard_order is missing #{item}")
          final_order << item
        end
      end

      @configs[:wildcard_order] = final_order
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

  def ask_create_config
    $stderr.puts "No configuration found at #{DEFAULT_PATH}. Create one? [y/n]"
    if $stdin.gets.chomp =~ /[yY]/
      FileUtils.cp(DEFAULT_CONFIG, DEFAULT_PATH)
      $stderr.puts "Created #{DEFAULT_PATH}"
      exit 0
    end
    exit 4
  end

  def self.tty?
    system('tty -s')
  end
end
