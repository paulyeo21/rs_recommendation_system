module IsNumeric
	# check if number
	def is_numeric?(obj) 
		obj.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
	end
end