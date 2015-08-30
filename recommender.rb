require_relative 'bi_hash'
require_relative 'is_numeric'
require_relative 'modified_hash'

class Recommender
	include IsNumeric

	def initialize
		@MAX_RECOMMENDATIONS = 5

		# users dataset {user_id : username, ...} {username : id, ...}
		@users = BiHash.new

		# users_items dataset {user_id : [item_id], ...}
		@user_items = Hash.new

		# to make building the cosine similarity matrix efficient, also store array of arrays for user_items
		# i.e. [{user_id: [item_id, ...]}, ...]
		@user_items_array = Array.new

		# cosine similarity matrix {user_id : {user_id : cosine_similarity_value, ...}}
		@cosine_similarity_matrix = Hash.new

		# items dataset {item_id : item_name, ...} {item_name : item_id, ...}
		@items = BiHash.new

		# users and categories id dataset {item_id : [category_id], ...}
		@item_categories = Hash.new

		# to make building the cosine similarity matrix efficient, also store array of arrays for item_categories
		# i.e. [{item_id: [category_id, ...]}, ...]
		@item_categories_array = Array.new
		
		# categories id and name dataset {category_id : category_name, ...}
		@categories = BiHash.new
	end

	# load user, item, category datasets into hashes
	def load_data path=''

		# load user data line by line to avoid slurp
		File.foreach(path + 'mini_proj-users.csv') do |line|
			# split line by user_id and user_name (user_id => user_name)
			user = split_id_name(line.strip)

			# add to users hash if not nil (i.e. id: name)
			@users.insert_array_values(user[0], user[1]) if user
		end
		# puts @users[35688]
		# puts @users['JACK I']

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
		# puts @user_items[37033]
		# puts @user_items[35717]

		# load user_items hash into user_items_array
		@user_items.each do |key, value|
			@user_items_array.push({key => value})
		end
		
		# load item id and item names to items data
		File.foreach(path + 'mini_proj-items.csv') do |line|
			# split item by tab
			item = line.strip.split("\t")

			# add to items hash if not nil
			@items[item[0].to_i] = item[1] if is_numeric?(item[0])
		end
		# puts @items[1610]
		# puts @items['Piston Pin #5']

		# load user category data
		File.foreach(path + 'mini_proj-categories_items.csv') do |line|
			# split user id and category id
			item_category = line.split(' ')

			if is_numeric?(item_category[0])

				# convert user id and category id to integers
				item_category = item_category.map(&:to_i)

				# if user id exists in hash then append to array of category ids else make new i.e. {user_id : [category_id, ...]}
				@item_categories[item_category[0]] ? @item_categories[item_category[0]].push(item_category[1]) : @item_categories[item_category[0]] = [item_category[1]]
			end
		end
		# puts @item_categories[1155]

		# load item_categories hash into item_categories_array
		@item_categories.each do |key, value|
			@item_categories_array.push({key => value})
		end

		# load category id names data
		File.foreach(path + 'mini_proj-categories.csv') do |line|
			# split line by category_id and category_name (category_id => category_name)
			category = split_id_name(line.strip)

			# add to users hash if not nil (i.e. id: name)
			@categories.insert_array_values(category[0], category[1]) if category
		end
		# puts @categories[124]
		# puts @categories['Unicycles']

	end

	# splits user id name information into array
	def split_id_name line
		user_id = ''

		for index in 0..line.length-1
			# append numbers to user id or finish when you hit space or non-numeric
			is_numeric?(line[index]) ? user_id += line[index] : break
		end

		# return if not nil
		user_id.empty? ? nil : [user_id.to_i, line[index+1..-1]]
	end

	# build user-user cosine similarity matrix
	# T: O((n ^ 2 - n) / 2)
	# S: O((n ^ 2 - n) / 2)
	def build_cosine_similarity_matrix strategy
		# build matrix depending on the input strategy
		strategy_hash = {"user-based" => @user_items_array, "content-based" => @item_categories_array}
		data = strategy_hash[strategy]

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

				# puts "comparing #{current_id}'s items: #{current_items}"
				# puts "with #{next_id}'s items: #{next_items}"

				# if current user key not in hash then create new hash i.e. {user_id: {pair_user_id : cosine_similarity_value, ...}}
				@cosine_similarity_matrix[current_id] = ModifiedHash.new if not @cosine_similarity_matrix.has_key?(current_id)
			
				# do to next => current as well
				@cosine_similarity_matrix[next_id] = ModifiedHash.new if not @cosine_similarity_matrix.has_key?(next_id)

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
	# function = x dot y / ||x|| * ||y||
	def compute_cosine_similarity current_items, next_items
		# find numerator by finding the number of the intersection of items
		numerator = (current_items & next_items).length

		# find denominator by finding the product of the square root of the number of items of each user
		denominator = Math.sqrt(current_items.length) * Math.sqrt(next_items.length)

		# puts "cosine similarity value of #{current_items} and #{next_items}: #{numerator/denominator}"
		# puts

		# return cosine similarity value
		numerator / denominator
	end

	# return an item of recommendation for user by strategy
	def recommend username, strategy
		# build cosine similarity matrix
		build_cosine_similarity_matrix(strategy)

		strategy == "user-based" ? user_based(username) : content_based(username)
	end

	def user_based username
		# get user id of input username
		user_id = @users[username]
		# puts "there are this many user_ids with the input username #{user_id}"

		# loop through user ids since there may be duplicates usernames
		user_id.each do |id|
			if @cosine_similarity_matrix.has_key?(id)
				# find closest user to each user id
				closest_user_id = @cosine_similarity_matrix[id].get_closest

				# puts "current user_id #{id}"
				# puts "closest_user_id #{closest_user_id}"
				# puts "current user items #{@user_items[id]}"
				# puts "other similarities #{@cosine_similarity_matrix[id]}"

				# if ties in closest similarities then we need to gather all items that should be recommended
				all_recommendable_items = []
				closest_user_id.each do |closest_id|
					# puts "closest_user #{closest_id}'s items #{@user_items[closest_id]}"
					all_recommendable_items += @user_items[closest_id]
				end

				# find username items that do not intersect with closest user items
				# and iterate through items to get their names
				recommend_items = []
				# print (all_recommendable_items - @user_items[id])
				# puts
				(all_recommendable_items - @user_items[id]).each do |item_id|
					recommend_items.push(@items[item_id])
				end
				
				# print output: recommended items with (username, user_id)
				recommend_items.empty? ? puts("No items to recommend (#{username}, #{id})") : puts("Recommend #{recommend_items} for (#{username}, #{id})")
			end
		end
	end

	def content_based username
		# get user id of input username
		user_id = @users[username]

		# check if user exists in data
		if user_id

			# loop through user ids since there may be duplicates usernames
			user_id.each do |id|
				
				# track all items that are closest by category to each item purchased by user
				closest_items = {}

				# puts "#{id}, #{@user_items[id]}"

				# check if user has items
				if @user_items[id]

					# for each item purchased by user
					@user_items[id].each do |item_id|

						if @cosine_similarity_matrix.has_key?(item_id)

							# puts "user's #{item_id} closest to: #{@cosine_similarity_matrix[item_id]}"

							# find closest items to each item id and keep track of them
							@cosine_similarity_matrix[item_id].each { |key, value| closest_items[key] = value }
						end
					end

					# puts "#{closest_items}"

					# sort closest items by decreasing cosine similarity value
					closest_items = closest_items.sort_by{|k, v| v}.reverse.map {|item| item[0]}

					# puts "#{closest_items}"

					# find username items that do not intersect with recommendable items (use array - array)
					# intersect with remaining array after (array - array) with itself to get rid of duplicates
					# and iterate through items to get their names
					recommend_item_ids = closest_items - @user_items[id]
					recommend_item_ids = recommend_item_ids & recommend_item_ids

					# max recommendations = 5
					recommend_item_ids = recommend_item_ids[0..@MAX_RECOMMENDATIONS]

					# puts "current user id #{id} and items #{@user_items[id]}"
					# puts "recommend items for user #{recommend_item_ids}"

					recommend_item_names = []

					recommend_item_ids.each do |item_id|
						recommend_item_names.push(@items[item_id]) if @items[item_id]
					end
						
					# print output: recommended items with (username, user_id)
					recommend_item_names.empty? ? puts("No items to recommend (#{username}, #{id})") : puts("Recommend #{recommend_item_names} for (#{username}, #{id})")
				end
			end

		else
			puts "No such user #{username} in dataset"
		end
	end

	# test with data from instructions 
	def test

		# user-based test data
		@users.insert_array_values(1, "John Doe")
		@users.insert_array_values(2, "Jane Doe")
		@users.insert_array_values(3, "Jim Doe")
		@items[1] = "Nike Dunks"
		@items[2] = "Nike Street Basketball"
		@items[3] = "Adidas Jersey"
		@items[4] = "Golf Bag"
		@user_items[1] = [1]
		@user_items[2] = [1,2]
		@user_items[3] = [2,4]
		@user_items_array.push({1 => [1]})
		@user_items_array.push({2 => [1,2]})
		@user_items_array.push({3 => [2,4]})

		# content-based test data
		@categories[1] = "Shoes"
		@categories[2] = "Basketball"
		@categories[3] = "Nike"
		@categories[4] = "Balls"
		@categories[5] = "Clothing"
		@categories[6] = "Adidas"
		@categories[7] = "Golf"
		@categories[8] = "Accessories"
		@item_categories[1] = [1,2,3]
		@item_categories[2] = [4,2,3]
		@item_categories[3] = [5,2,6]
		@item_categories[4] = [7,8]
		@item_categories_array.push({1 => [1,2,3]})
		@item_categories_array.push({2 => [4,2,3]})
		@item_categories_array.push({3 => [5,2,6]})
		@item_categories_array.push({4 => [7,8]})

		# recommend("John Doe", "user-based")
		recommend("J.J A", "content-based")
	end

# end recommender class
end


a = Recommender.new
a.load_data('data/')
# print a.split_id_name('user_id	name')
# print a.split_id_name('35713	JUSTIN I')
# a.build_cosine_similarity_matrix("user-based")
a.recommend("J.J A", "user-based")

# a.test
