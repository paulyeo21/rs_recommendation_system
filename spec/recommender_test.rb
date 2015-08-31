require_relative 'spec_helper'
require_relative '../lib/recommender'

RSpec.describe Recommender do
	r = Recommender.new
	r.load_data("data/")
	
	it "test users data" do
		expect(r.get_users(35688)).to eq("JACK I")
	end

	it "test user items data" do
		expect(r.get_user_items(35688)).to eq([1289, 1457, 1332])
	end

	it "test items data" do
		expect(r.get_items(1166)).to eq("26'' Micargi Womens Tahiti")
	end

end
