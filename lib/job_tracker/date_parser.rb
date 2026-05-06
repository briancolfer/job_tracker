# frozen_string_literal: true
# lib/job_tracker/date_parser.rb
require 'date'
require 'chronic'

module JobTracker
  class DateParser
    def self.parse(input)
      return nil if input.nil?

      # Strict first
      if input.match?(/^\d{4}-\d{2}-\d{2}$/)
        return Date.parse(input)
      end

      # Natural language fallback
      parsed = Chronic.parse(input)
      return parsed.to_date if parsed

      raise ArgumentError, "Could not understand date: #{input}"
    end
  end
end
