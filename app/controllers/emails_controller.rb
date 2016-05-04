class EmailsController < ApplicationController

  # Disable CSRF protection
  skip_before_action :verify_authenticity_token

  def create
    # process various message parameters:
    sender  = params['from']
    receiver = params['to']
    subject = params['subject']

    # get the "stripped" body of the message, i.e. without
    # the quoted part
    actual_body = params["stripped-text"]
    body_html = params["body-html"]

    # TODO:
    # process all attachments:
#    count = params['attachment-count'].to_i
#    count.times do |i|
#      stream = params["attachment-#{i+1}"]
#      filename = stream.original_filename
#      data = stream.read()
#    end

    email = Email.new
    email.sender = sender
    email.receiver = receiver
    email.subject = subject
    email.actual_body = actual_body
    email.body_html = body_html

    email.save

    render json: { hello: "world" }
  end

end
