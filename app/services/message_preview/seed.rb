# app/services/message_preview/seed.rb
# frozen_string_literal: true

module MessagePreview
  class Seed
    PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")

    def self.call
      message = PreviewMessage.first_or_initialize(subject: "Your synthetic operations report")
      message.update!(recipient: "operator@example.test", sender: "showcase@example.test", text_body: "The synthetic report is ready.", html_body: "<h1>Report ready</h1><p>Safe synthetic content.</p><script>alert('removed')</script>")
      attach(message, "chart.png", "image/png", PNG)
      attach(message, "report.pdf", "application/pdf", "%PDF-1.4\n% synthetic preview\n")
      attach(message, "brief.docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "Synthetic document download")
      message
    end

    def self.attach(message, filename, content_type, body)
      return if message.attachments.any? { |attachment| attachment.filename.to_s == filename }
      message.attachments.attach(io: StringIO.new(body), filename:, content_type:)
    end
    private_class_method :attach
  end
end
