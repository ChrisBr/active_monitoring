class BooksController < ApplicationController
  def create
    Book.create(name: "name")

    render plain: "ok"
  end
end
