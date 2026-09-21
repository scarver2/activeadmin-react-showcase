# app/helpers/showcase_icons_helper.rb
# frozen_string_literal: true

require "json"

# Decorative presentation only: callers must retain the adjacent visible label.
module ShowcaseIconsHelper
  ICON_REGISTRY = JSON.parse(Rails.root.join("app/frontend/icons/registry.json").read, freeze: true)
  ICON_NAMES = ICON_REGISTRY.keys.freeze

  def showcase_icon(name, landmark: false)
    raise ArgumentError, "Unknown showcase icon" unless ICON_NAMES.include?(name.to_s)

    tag.svg(class: "showcase-icon", viewBox: "0 0 24 24", aria: { hidden: true }, focusable: "false") do
      safe_join([
        tag.use(href: "/showcase-icons.svg##{ICON_REGISTRY.fetch(name.to_s).fetch('symbol')}",
                class: landmark ? "showcase-icon-default" : nil),
        landmark ? tag.use(href: "/showcase-icons.svg#landmark", class: "showcase-icon-landmark") : nil
      ].compact)
    end
  end
end
