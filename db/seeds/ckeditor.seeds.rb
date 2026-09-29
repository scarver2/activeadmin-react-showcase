# db/seeds/ckeditor.seeds.rb
# frozen_string_literal: true

after :admin do
  admin = AdminUser.find_by!(email: ENV.fetch("SHOWCASE_ADMIN_EMAIL", "admin@example.test"))
  article = admin.ckeditor_articles.find_or_initialize_by(title: "CKEditor editing stays Rails-owned")
  article.update!(
    body_html: <<~HTML,
      <h2>Focused editing, explicit authority</h2>
      <p><strong>CKEditor 5</strong> enhances an ordinary Rails textarea without taking over the record lifecycle.</p>
      <h3>Editorial checklist</h3>
      <ul>
        <li>Use headings and emphasis to make operational notes scannable.</li>
        <li>Keep links explicit and server-sanitized.</li>
        <li>Keep uploads behind a separate Rails-owned media boundary.</li>
      </ul>
      <blockquote>The editor improves authoring; Rails decides what survives.</blockquote>
      <pre><code>article.update!(body_html: submitted_html)</code></pre>
      <p>Compare this self-hosted HTML boundary with the independent Lexical and TinyMCE experiments.</p>
    HTML
    summary: "A self-hosted CKEditor 5 experiment over a Rails-authoritative HTML boundary."
  )
end
