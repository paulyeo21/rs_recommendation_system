# Ignore this file:
# holds old code that has been replaced, but may come in handy later

		# iterate over user_items hash
		# @user_items.each do |current_user, current_items|
		# 	@user_items.each do |next_user, next_items|
		# 		# if current user and next user are not same, then find cosine similarity value of two
		# 	  if current_user != next_user
		# 			# if current user does not exist, initialize hash values with empty modified hash
		# 			# else compute similarity between users from items and append to modified hash
		# 			if @cosine_similarity_matrix.has_key?(current_user)
		# 				@cosine_similarity_matrix[current_user][next_user] = compute_cosine_similarity(current_items, next_items)
		# 			else
		# 				@cosine_similarity_matrix[current_user] = ModifiedHash.new
		# 			end
		# 		end
		# 	end
		# end
		# puts @cosine_similarity_matrix[35716].get_closest
		# puts @cosine_similarity_matrix[35717]