
class Mpc
	def mpccall(cmd)
		call = "mpc #{cmd}"
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

	def current
		`mpc --format '%file%' current`
	end

	#TODO use method_missing for clear, play and everything that will come
end
