# app/helpers/showcase_icons_helper.rb
# frozen_string_literal: true

# Decorative presentation only: callers must retain the adjacent visible label.
module ShowcaseIconsHelper
  ICON_NAMES = %w[dashboard records people reports].freeze

  def showcase_icon(name, landmark: false)
    raise ArgumentError, "Unknown showcase icon" unless ICON_NAMES.include?(name.to_s)

    tag.svg(class: "showcase-icon", viewBox: "0 0 24 24", aria: { hidden: true }, focusable: "false") do
      safe_join([
        tag.use(href: "/showcase-icons.svg##{name}", class: landmark ? "showcase-icon-default" : nil),
        landmark ? tag.use(href: "/showcase-icons.svg#landmark", class: "showcase-icon-landmark") : nil
      ].compact)
    end
  end
end
