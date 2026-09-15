# config/initializers/paper_trail.rb
# frozen_string_literal: true

# JSON avoids unsafe YAML object deserialization at the audit boundary.
PaperTrail.serializer = PaperTrail::Serializers::JSON
