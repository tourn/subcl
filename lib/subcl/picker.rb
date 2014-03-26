class Picker
  def initialize(ary)
    @available = ary
    if ary.empty? then
      raise ArgumentError, "Cannot initialize Picker with an empty array!"
    end
  end

  def pick
    choices = {}

    #TODO add type column when multiple types are available

    counter_padding = @available.length.to_s.length
    i = 1
    @available.each do |elem|
      choices[i] = elem
      #TODO add padding for numbers with one digit
      $stderr.print "[#{i.to_s.rjust(counter_padding)}] "
      yield(elem)
      i = i + 1
    end


    begin
      picks = []
      valid = true
      $stderr.print "Pick any: "

      choice = $stdin.gets

      return @available if choice.chomp == 'all'

      choice.split(/[ ,]+/).each do |part|
        possibleRange = part.split(/\.\.|-/)
        if possibleRange.length == 2
          start = possibleRange[0].to_i
          stop = possibleRange[1].to_i
          [start, stop].each do |num|
            valid = validate(num)
          end
          (start..stop).each do |num|
            picks << choices[num]
          end

        elsif validate(num = part.to_i)
          picks << choices[num]
        else
          valid == false
        end
      end
    end while !valid

    return picks
  end

  def validate(pickNum)
    #no -1, we start filling choices{} at 1
    if pickNum > 0 and pickNum <= @available.length
      true
    else
      $stderr.puts "Invalid pick. Try again."
      false
    end
  end

end
