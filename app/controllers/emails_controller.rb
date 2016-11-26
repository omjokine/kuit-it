class EmailsController < ApplicationController

  before_action :authenticate_user!, only: :index

  # Disable CSRF protection
  skip_before_action :verify_authenticity_token

  def index
    user_address = "#{current_user.username}#{ENV['EMAIL_DOMAIN']}"
    @emails = Email.where("lower(receiver) = ?", user_address.downcase)
  end

  def create
    # process various message parameters:
    sender  = params['from']
    receiver = params['recipient']
    subject = params['subject']

    # get the "stripped" body of the message, i.e. without
    # the quoted part
    actual_body = params["stripped-text"]
    body_html = params["stripped-html"]

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

    user = User.where("lower(username) = ?", receiver.downcase.split("@")[0].downcase).first

    if user
      from = SendGrid::Email.new(email: "#{user.username}#{ENV['EMAIL_DOMAIN']}")
      subject = email.subject
      to = SendGrid::Email.new(email: user.email)
      content = SendGrid::Content.new(
        type: 'text/html',
        value: strip_out_mozilla_forward_headers(email.body_html)
      )
      mail = SendGrid::Mail.new(from, subject, to, content)

      attachment = SendGrid::Attachment.new
      attachment.content = Base64.strict_encode64(generate_pdf(email.body_html))
      attachment.type = 'application/pdf'
      attachment.filename = "#{friendly_filename(email.subject)}.pdf"

      mail.attachments = attachment

      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      response = sg.client.mail._('send').post(request_body: mail.to_json)
    end

    render json: { hello: "world" }
  end

  def download_pdf
    email = Email.find(params[:id])

    unless email
      render json: { error: "Incorrect id." }
      return
    end

    begin
      # send the generated PDF
      send_data(generate_pdf(email.body_html),
        filename: "kuit-it.pdf",
        type: "application/pdf",
        disposition: "attachment")
      rescue Pdfcrowd::Error => why
        render text: why
      end
  end

  private

  def friendly_filename(filename)
    filename.gsub(/[^\w\s_-]+/, '')
            .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
            .gsub(/\s+/, '_')
  end

  def generate_pdf body
    # convert a web page and store the generated PDF to a variable
    WickedPdf.new.pdf_from_string(strip_out_mozilla_forward_headers(body))
  end

  def strip_out_mozilla_forward_headers html
    html_to_be_stripped_out = html[/(moz-forward-container\">)(.*)(<meta)/m, 2]
    return html unless html_to_be_stripped_out
    html.gsub(html_to_be_stripped_out, "")
  end

end
