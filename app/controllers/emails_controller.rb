class EmailsController < ApplicationController

  before_action :authenticate_user!

  # Disable CSRF protection
  skip_before_action :verify_authenticity_token

  def index
    @emails = Email.all
  end

  def create
    # process various message parameters:
    sender  = params['from']
    receiver = params['recipient']
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

  def download_pdf
    email = Email.find(params[:id])

    unless email
      render json: { error: "Incorrect id." }
      return
    end

    begin
      # create an API client instance
      client = Pdfcrowd::Client.new("#{ENV['PDFCROWD_USER']}",
                                    "#{ENV['PDFCROWD_API_KEY']}")

      # convert a web page and store the generated PDF to a variable
      pdf = client.convertHtml(strip_out_mozilla_forward_headers(email.body_html))

      # send the generated PDF
      send_data(pdf,
        filename: "kuit-it.pdf",
        type: "application/pdf",
        disposition: "attachment")
      rescue Pdfcrowd::Error => why
        render text: why
      end
  end

  private

  def strip_out_mozilla_forward_headers html
    html_to_be_stripped_out = html[/(moz-forward-container\">)(.*)(<meta)/m, 2]
    return html unless html_to_be_stripped_out
    html.gsub(html_to_be_stripped_out, "")
  end

end
