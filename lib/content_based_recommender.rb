require_relative 'recommender'

class ContentBasedRecommender < Recommender

	def initialize
		super

		# users and categories id dataset {item_id : [category_id], ...}
		@item_categories = Hash.new

		# to make building the cosine similarity matrix efficient, also store array of arrays for item_categories
		# i.e. [{item_id: [category_id, ...]}, ...]
		@item_categories_array = Array.new
		
		# categories id and name dataset {category_id : category_name, ...}
		@categories = BiHash.new

		# load data into hashes
		load_data('data/')
		load_test_data

		# from superclass Recommender
		build_cosine_similarity_matrix
	end

	# load additional data that this class needs
	def load_data path
		super

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
	end

	# get item categories
	def get_item_categories item_id
		@item_categories[item_id]
	end

	# get categories
	# input: either category id or category name
	def get_categories input
		@categories[input]
	end

	# content-based filtering
	# output: array of items names to recommend
	def recommendations username
		# get user id of input username
		user_id = @users[username]

		# check if user exists in data
		if user_id

			# loop through user ids since there may be duplicates usernames
			user_id.each do |id|

				# track all items that are closest by category to each item purchased by user
				closest_items = {}

				# check if user has items
				if @user_items[id]

					# for each item purchased by user
					@user_items[id].each do |item_id|

						if @cosine_similarity_matrix[item_id]

							# find closest items to each item id and keep track of them
							@cosine_similarity_matrix[item_id].each { |key, value| closest_items[key] = value }
						end
					end

					# sort closest items by decreasing cosine similarity value
					closest_items = closest_items.sort_by{|k, v| v}.reverse.map {|item| item[0]}

					# find username items that do not intersect with recommendable items (use array - array)
					# intersect with remaining array after (array - array) with itself to get rid of duplicates
					# and iterate through items to get their names
					recommend_item_ids = closest_items - @user_items[id]
					recommend_item_ids = recommend_item_ids & recommend_item_ids

					# max recommendations = 5
					recommend_item_ids = recommend_item_ids[0..@MAX_RECOMMENDATIONS-1]

					# convert recommendation items id into names
					recommend_item_names = []
					recommend_item_ids.each do |item_id|
						recommend_item_names.push(@items[item_id]) if @items[item_id]
					end

					# return recommended item names
					return recommend_item_names
				end
			end
		else
			return "No such user \"#{username}\" in dataset"
		end
	end

	# print what to recommend whom or no items to recommend
	def recommend username
		recommend_item_names = recommendations(username)
		return recommend_item_names.empty? ? "No items to recommend #{username}" : "Recommend #{recommend_item_names} for #{username}"
	end

	# test run using data from instructions
	def load_test_data
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
	end
end


def main
	puts ARGV.length == 1 ? ContentBasedRecommender.new.recommend(ARGV[0]) : "Recommender system takes one username as input"
end

main
