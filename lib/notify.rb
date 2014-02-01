class Notify

	SupportedMethods = %w{notify-send growlnotify awesome-client}
	Icon = File.dirname(__FILE__) + "/../share/icon.png"

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
				@binary = get_binary(method)
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
			@binary = get_binary(notifyMethod) 
			@method = notifyMethod
			raise ArgumentError, "No binary found for #{notifyMethod} in PATH" if @binary.nil?
		end
	end

	def get_binary(name)
		binary = `which #{name}`.chomp
		if $?.success?
			binary
		else
			nil
		end
	end

	def notify(message)
		case @method
		when nil
			#great, do nothing
		when "notify-send"
			system("notify-send --icon #{Icon} --urgency critical Subcl '#{message}'")
		when "growlnotify"
			system("growlnotify --image #{Icon} --title Subcl --message '#{message}'")
		when "awesome-client"
			naughtyCmd = %Q{
				naughty.notify({
					title='subcl',
					text='#{message}',
					icon='#{Icon}',
					timeout = 10
				}) 
			}
			naughtyCmd.gsub! "\n" " "

			system(%Q{echo "#{naughtyCmd}" | awesome-client})
		end
	end
end

