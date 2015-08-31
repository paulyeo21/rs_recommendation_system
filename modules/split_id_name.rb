module SplitIdName
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
end