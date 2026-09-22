# db/seeds/tiny_mce.seeds.rb
# frozen_string_literal: true

after :admin do
  admin = AdminUser.find_by!(email: ENV.fetch("SHOWCASE_ADMIN_EMAIL", "admin@example.test"))
  article = admin.tiny_mce_articles.find_or_initialize_by(title: "Self-hosted editing stays Rails-owned")
  article.update!(
    body_html: <<~HTML,
      <h2>Modern editing, familiar boundary</h2>
      <p><strong>TinyMCE</strong> enhances an ordinary Rails textarea while the server retains authority.</p>
      <h3>Operator checklist</h3>
      <ul>
        <li>Use headings and emphasis to establish hierarchy.</li>
        <li>Keep links explicit and server-sanitized.</li>
        <li>Store uploads through the Rails-owned Asset Manager.</li>
      </ul>
      <blockquote>The browser proposes; Rails sanitizes and persists.</blockquote>
      <pre><code>document.update!(body_html: submitted_html)</code></pre>
      <p>Compare this HTML-first boundary with the neighboring Lexical structured-document experiment.</p>
    HTML
    summary: "A self-hosted TinyMCE editor over a Rails-authoritative HTML boundary."
  )
end
