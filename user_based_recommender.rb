require_relative 'recommender'

class UserBasedRecommender < Recommender

	def initialize
		super

		# to make building the cosine similarity matrix efficient, also store array of arrays for user_items
		# i.e. [{user_id: [item_id, ...]}, ...]
		@user_items_array = Array.new

		# load data into hashes
		load_data('data/')

		# from superclass Recommender
		build_cosine_similarity_matrix
	end

	# load additional data that this class needs
	def load_data path=''
		super

		# load user_items hash into user_items_array
		@user_items.each do |key, value|
			@user_items_array.push({key => value})
		end
	end

	# user-based filtering
	def recommend username
		# get user id of input username
		user_id = @users[username]

		# check if user exists in data
		if user_id
	
			# loop through user ids since there may be duplicates usernames
			user_id.each do |id|

				if @cosine_similarity_matrix[id]

					# find closest user to each user id
					closest_users_id = @cosine_similarity_matrix[id]

					# sort closest users by decreasing cosine similarity value
					closest_users_id = closest_users_id.sort_by{|k, v| v}.reverse.map {|item| item[0]}

					# if ties in closest similarities then we need to gather all items that should be recommended
					recommend_item_ids = []
					closest_users_id.each do |closest_id|
						recommend_item_ids += @user_items[closest_id]
					end

					# find username items that do not intersect with recommendable items (use array - array)
					# intersect with remaining array after (array - array) with itself to get rid of duplicates
					# and iterate through items to get their names
					recommend_item_ids = recommend_item_ids - @user_items[id]
					recommend_item_ids = recommend_item_ids & recommend_item_ids

					# max recommendations = 5
					recommend_item_ids = recommend_item_ids[0..@MAX_RECOMMENDATIONS-1]

					# convert recommendation items id into names
					recommend_item_names = []
					recommend_item_ids.each do |item_id|
						recommend_item_names.push(@items[item_id]) if @items[item_id]
					end
					
					# print output: recommended items with (username, user_id)
					recommend_item_names.empty? ? puts("No items to recommend (#{username}, #{id})") : puts("Recommend #{recommend_item_names} for (#{username}, #{id})")
					puts
				end
			end
		else
			puts "No such user #{username} in dataset"
		end
	end

	# test run using data from instructions
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
		
		build_cosine_similarity_matrix
		recommend("John Doe")
		recommend("Jane Doe")
		recommend("Jim Doe")
	end
end

a = UserBasedRecommender.new
a.recommend("JOHN U")
a.recommend("J.J A")
a.test
