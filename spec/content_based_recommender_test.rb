require_relative 'spec_helper'
require_relative '../lib/content_based_recommender'

RSpec.describe ContentBasedRecommender do
	a = ContentBasedRecommender.new

	it "test item categories data" do
		expect(a.get_item_categories(1299)).to eq([129, 154, 168])
	end

	it "test categories data" do
		expect(a.get_categories(138)).to eq("Helmets")
	end

	# test data from instructions
	it "test on John Doe" do
		expect(a.recommendations("John Doe")).to eq(["Nike Street Basketball", "Adidas Jersey"])
		expect(a.recommend("John Doe")).to eq("Recommend [\"Nike Street Basketball\", \"Adidas Jersey\"] for John Doe")
	end

	it "test on Jane Doe" do
		expect(a.recommendations("Jane Doe")).to eq(["Adidas Jersey"])
		expect(a.recommend("Jane Doe")).to eq("Recommend [\"Adidas Jersey\"] for Jane Doe")
	end

	it "test on Jim Doe" do
		expect(a.recommendations("Jim Doe")).to eq(["Nike Dunks", "Adidas Jersey"])
		expect(a.recommend("Jim Doe")).to eq("Recommend [\"Nike Dunks\", \"Adidas Jersey\"] for Jim Doe")	
	end
end
