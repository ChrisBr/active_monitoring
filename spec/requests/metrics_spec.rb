require "rails_helper"

RSpec.describe "ActionController metrics", type: :request do
  it "works" do
    post books_path

    expect(response.status).to be 200
  end
end
