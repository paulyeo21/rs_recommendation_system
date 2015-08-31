require_relative 'bi_hash'
require_relative 'modified_hash'
require_relative '../modules/is_numeric'
require_relative '../modules/split_id_name'

class Recommender
	include IsNumeric
	include SplitIdName

	def initialize
		# maximum number of recommendations output
		@MAX_RECOMMENDATIONS = 5

		# users dataset {user_id : username, ...} {username : id, ...}
		@users = BiHash.new

		# users_items dataset {user_id : [item_id], ...}
		@user_items = Hash.new

		# items dataset {item_id : item_name, ...} {item_name : item_id, ...}
		@items = BiHash.new

		# cosine similarity matrix {user_id : {user_id : cosine_similarity_value, ...}}
		@cosine_similarity_matrix = Hash.new
	end

	# load user, item, category datasets into hashes
	def load_data path

		# load user data line by line to avoid slurp
		File.foreach(path + 'mini_proj-users.csv') do |line|
			# split line by user_id and user_name (user_id => user_name)
			user = split_id_name(line.strip)

			# add to users hash if not nil (i.e. id: name)
			@users.insert_array_values(user[0], user[1]) if user
		end

		# load user items data
		File.foreach(path + 'mini_proj-items_users.csv') do |line|
			# split line by white space (user_id => item_id)
			user_item = line.split(' ')

			# if user_id is id
			if is_numeric?(user_item[0])

				# convert user id and item id to integers
				user_item = user_item.map(&:to_i)

				# if user id exists add item_id to existing array of items
				@user_items[user_item[0]] ? @user_items[user_item[0]].push(user_item[1]) : @user_items[user_item[0]] = [user_item[1]]
			end
		end

		# load item id and item names to items data
		File.foreach(path + 'mini_proj-items.csv') do |line|
			# split item by tab
			item = line.strip.split("\t")

			# add to items hash if not nil
			@items[item[0].to_i] = item[1] if is_numeric?(item[0])
		end
	end

	# get username or userid 
	# input: either user_id or user_name
	def get_users input
		@users[input]
	end

	# get user items
	def get_user_items user_id
		@user_items[user_id]
	end

	# get items
	# input: either item_id or item_name
	def get_items input
		@items[input]
	end

	# build user-user cosine similarity matrix
	# T: O((n ^ 2 - n) / 2)
	# S: O((n ^ 2 - n) / 2)
	def build_cosine_similarity_matrix
		# build matrix depending on the strategy
		strategy_hash = {"UserBasedRecommender" => @user_items_array, "ContentBasedRecommender" => @item_categories_array}
		data = strategy_hash[self.class.name]

		for i in 0..data.length-2

			current_id = nil
			current_items = nil
			data[i].each do |key, value|
				current_id = key
				current_items = value
			end

			for j in i+1..data.length-1

				next_id = nil
				next_items = nil
				data[j].each do |key, value|
					next_id = key
					next_items = value
				end

				# if current user key not in hash then create new hash i.e. {user_id: {pair_user_id : cosine_similarity_value, ...}}
				@cosine_similarity_matrix[current_id] = ModifiedHash.new if not @cosine_similarity_matrix[current_id]
			
				# do to next => current as well
				@cosine_similarity_matrix[next_id] = ModifiedHash.new if not @cosine_similarity_matrix[next_id]

				# add to hash
				cosine_similarity_value = compute_cosine_similarity(current_items, next_items)

				if cosine_similarity_value > 0
					@cosine_similarity_matrix[current_id][next_id] = cosine_similarity_value
					@cosine_similarity_matrix[next_id][current_id] = cosine_similarity_value
				end
			end
		end
	end

	# output hash of cosine similarity values
	# formula: x dot y / ||x|| * ||y||
	def compute_cosine_similarity current_items, next_items
		# find numerator by finding the number of the intersection of items
		numerator = (current_items & next_items).length

		# find denominator by finding the product of the square root of the number of items of each user
		denominator = Math.sqrt(current_items.length) * Math.sqrt(next_items.length)

		# return cosine similarity value
		numerator / denominator
	end

end
