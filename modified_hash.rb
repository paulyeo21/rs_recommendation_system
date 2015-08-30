# modified_hash is a hash class that tracks closest and farthest user by cosine similarity value for a user

class ModifiedHash < Hash

	def initialize
		super
		@largest = nil
		@closest = []
		# @farthest = nil
	end

	def []= key, value 
		super
		if @largest.nil?
			@largest = value
			@closest = [key]
		elsif value == @largest
			@closest.push(key)
		elsif value > @largest
			@largest = value
			@closest = [key]
		end
		# puts "current key, value: #{key}, #{value}"
		# puts "largest value so far: #{@largest}"
		# puts "closest user so far: #{@closest}"
		# puts
	end

	def get_closest
		@closest
	end

end

# modified_hash = ModifiedHash.new('a', 1)
# modified_hash['a'] = 1
# modified_hash['b'] = 2
# modified_hash['c'] = 2
# puts modified_hash.get_closest
