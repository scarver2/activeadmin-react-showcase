# db/seeds/content.seeds.rb
# frozen_string_literal: true

article = ShowcaseArticle.find_or_initialize_by(title: "Rich editing stays Rails-owned")
document = JSON.generate(
  root: {
    children: [
      { children: [ { detail: 0, format: 1, mode: "normal", style: "", text: "Rodeo operations briefing",
                      type: "text", version: 1 } ], direction: nil, format: "", indent: 0, tag: "h2",
        type: "heading", version: 1 },
      { children: [
        { detail: 0, format: 0, mode: "normal", style: "", text: "A production-minded editor keeps ",
          type: "text", version: 1 },
        { detail: 0, format: 3, mode: "normal", style: "", text: "creative flow", type: "text", version: 1 },
        { detail: 0, format: 0, mode: "normal", style: "", text: " in React while Rails remains the authority.",
          type: "text", version: 1 }
      ], direction: nil, format: "", indent: 0, type: "paragraph", version: 1 },
      { children: [
        { children: [ { detail: 0, format: 0, mode: "normal", style: "", text: "Canonical Lexical JSON",
                        type: "text", version: 1 } ], direction: nil, format: "", indent: 0, type: "listitem",
          value: 1, version: 1 },
        { children: [ { detail: 0, format: 8, mode: "normal", style: "", text: "Server-validated links and rendering",
                        type: "text", version: 1 } ], direction: nil, format: "", indent: 0, type: "listitem",
          value: 2, version: 1 },
        { children: [ { detail: 0, format: 0, mode: "normal", style: "", text: "Optimistic locking without lost drafts",
                        type: "text", version: 1 } ], direction: nil, format: "", indent: 0, type: "listitem",
          value: 3, version: 1 }
      ], direction: nil, format: "", indent: 0, listType: "bullet", start: 1, tag: "ul", type: "list", version: 1 },
      { children: [ { detail: 0, format: 2, mode: "normal", style: "", text: "The browser proposes; Rails disposes.",
                      type: "text", version: 1 } ], direction: nil, format: "", indent: 0, type: "quote", version: 1 },
      { children: [
        { detail: 0, format: 0, mode: "normal", style: "", text: "Explore the ", type: "text", version: 1 },
        { children: [ { detail: 0, format: 1, mode: "normal", style: "", text: "ActiveAdmin project",
                        type: "text", version: 1 } ], direction: nil, format: "", indent: 0, rel: nil,
          target: nil, title: nil, type: "link", url: "https://activeadmin.info", version: 1 },
        { detail: 0, format: 0, mode: "normal", style: "", text: " that frames this showcase.", type: "text", version: 1 }
      ], direction: nil, format: "", indent: 0, type: "paragraph", version: 1 }
    ],
    direction: nil,
    format: "",
    indent: 0,
    type: "root",
    version: 1
  }
)
article.update!(
  editor_state: document,
  summary: "A safe rich-text boundary demonstrated by one focused React island."
)

ShowcaseAssets::Seed.call
