require_relative '../modules/is_numeric'

class BiHash < Hash
	include IsNumeric
	
	def initialize
		# id: name
		@forward = Hash.new
		# name: [id] (array of ids because name can be duplicate)
		@backward = Hash.new
	end

	def insert key, value
		if is_numeric? key
			@forward[key] = value
			@backward[value] = key
		else
			@forward[value] = key
			@backward[key] = value
		end
	end

	def insert_array_values key, value
		if is_numeric? key
			@forward[key] = value
			# If name already exists add id to array of ids, else create new
			@backward[value] ? @backward[value].push(key) : @backward[value] = [key]
		else
			@forward[value] = key
			# If name already exists add id to array of ids, else create new
			@backward[key] ? @backward[key].push(value) : @backward[key] = value
		end
	end

	def []= key, value
		insert key, value
	end

	def get key
		is_numeric?(key) ? @forward[key] : @backward[key]
	end

	def [] key
		get key
	end

	def show
		puts @forward
		puts @backward
	end

	def to_s
		# show
	end

end

# bihash = BiHash.new
# bihash['a'] = 1
# bihash[2] = 'b'
# puts bihash
# bihash.show
# puts bihash['a']
