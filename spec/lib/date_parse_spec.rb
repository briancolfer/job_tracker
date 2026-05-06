# frozen_string_literal: true

require "rails_helper" # or spec_helper if not a Rails-loaded spec
require "job_tracker/date_parser"

RSpec.describe JobTracker::DateParser do
  describe ".parse" do
    context "with ISO date format (YYYY-MM-DD)" do
      it "parses a valid ISO date" do
        result = described_class.parse("2026-05-01")
        expect(result).to eq(Date.new(2026, 5, 1))
      end

      it "does not rely on Chronic for ISO dates" do
        expect(Chronic).not_to receive(:parse)
        described_class.parse("2026-05-01")
      end

      it "raises error for invalid ISO date" do
        expect {
          described_class.parse("2026-13-01")
        }.to raise_error(ArgumentError)
      end
    end

    context "with natural language input" do
      around do |example|
        # Freeze time so tests are deterministic
        travel_to(Time.new(2026, 5, 5, 12, 0, 0)) { example.run }
      end

      it "parses '1 week ago'" do
        result = described_class.parse("1 week ago")
        expect(result).to eq(Date.new(2026, 4, 28))
      end

      it "parses 'yesterday'" do
        result = described_class.parse("yesterday")
        expect(result).to eq(Date.new(2026, 5, 4))
      end

      it "parses 'tomorrow'" do
        result = described_class.parse("tomorrow")
        expect(result).to eq(Date.new(2026, 5, 6))
      end

      it "parses 'last monday'" do
        result = described_class.parse("last monday")
        expect(result).to be_a(Date)
      end

      it "falls back to Chronic when not ISO" do
        expect(Chronic).to receive(:parse).with("yesterday").and_call_original
        described_class.parse("yesterday")
      end
    end

    context "with invalid input" do
      it "raises error when Chronic cannot parse" do
        expect {
          described_class.parse("not a real date")
        }.to raise_error(ArgumentError, /Could not understand date/)
      end
    end

    context "with nil input" do
      it "returns nil" do
        expect(described_class.parse(nil)).to be_nil
      end
    end
  end
end
