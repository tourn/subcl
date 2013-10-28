class Notify

	SupportedMethods = %w{notify-send growlnotify}

	def initialize(notifyMethod)
		@method = nil

		case notifyMethod
		when nil
			#do nothing
		when "none"
			#do nothing
		when "auto"
			#auto detect notifier lib
			SupportedMethods.each do |method|
				@binary = getBinary(method)
				unless @binary.nil?
					@method = method
					break
				end
			end
		else
			#use specified binary
			unless SupportedMethods.include? notifyMethod
				raise ArgumentError, "Notification method #{notifyMethod} is not supported"
			end
			@binary = getBinary(notifyMethod) 
			@method = notifyMethod
			raise ArgumentError, "No binary found for #{notifyMethod} in PATH" if @binary.nil?
		end
	end

	def getBinary(name)
		binary = `which #{name}`.chomp
		if $?.success?
			binary
		else
			nil
		end
	end

	#TODO add a subsonic icon
	def notify(message)
		case @method
		when nil
			#great, do nothing
		when "notify-send"
			system("notify-send --urgency critical '#{message}'")
		when "growlnotify"
			system("growlnotify --title Subcl --message '#{message}'")
		end
	end
end

