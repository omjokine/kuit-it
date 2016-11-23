class EncryptRequestsController < ApplicationController
  def letsencrypt
    # use your code here, not mine
    render text: ENV['LETS_ENCRYPT_CODE']
  end
end
