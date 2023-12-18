class Api::HelloController < ApplicationController
  def create
    render json: { message: 'Hello World' }
  end
end
