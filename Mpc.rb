
class Mpc
	def mpccall(cmd)
		call = "/usr/local/bin/mpc #{cmd}"
		unless system(call)
			print "MPC call error: #{$?}\n"
		end

	end

	def add(url)
		mpccall("add '#{url}'")
	end

	def play
		mpccall("play")
	end

	def clear
		mpccall("clear")
	end

	#TODO use method_missing for clear, play and everything that will come
end
