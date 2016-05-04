class EmailsController < ApplicationController

  # Disable CSRF protection
  skip_before_action :verify_authenticity_token

  def create
    puts params
    render json: { hello: "world" }
  end

end
