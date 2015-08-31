require_relative 'spec_helper'
require_relative '../lib/user_based_recommender'

RSpec.describe UserBasedRecommender do
	a = UserBasedRecommender.new

	# these tests are on "mini_proj-items_users.csv" and not the "full_mini_proj-items_users.csv"
	it "test on random user" do
		expect(a.recommendations("J.J A")).to eq(["Clutch Cable", "EPA Certified Black Muffler", "CDI Electron Ignition Coil", "Chain Idler Pulley with Bearing Wheel"])
	end

	it "test on non-user" do
		expect(a.recommendations("This is not a user!")).to eq("No such user \"This is not a user!\" in dataset")
	end

	# test data from instructions
	it "test on John Doe" do
		expect(a.recommendations("John Doe")).to eq(["Nike Street Basketball"])
		expect(a.recommend("John Doe")).to eq("Recommend [\"Nike Street Basketball\"] for John Doe")
	end

	it "test on Jane Doe" do
		expect(a.recommendations("Jane Doe")).to eq(["Golf Bag"])
		expect(a.recommend("Jane Doe")).to eq("Recommend [\"Golf Bag\"] for Jane Doe")
	end

	it "test on Jim Doe" do
		expect(a.recommendations("Jim Doe")).to eq(["Nike Dunks"])
		expect(a.recommend("Jim Doe")).to eq("Recommend [\"Nike Dunks\"] for Jim Doe")
	end
end
