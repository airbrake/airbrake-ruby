require 'spec_helper'

RSpec.describe Airbrake::CodeHunk do
  describe "#to_h" do
    context "when a file is empty" do
      subject { described_class.new(fixture_path('empty_file.rb'), 1).to_h }

      it { is_expected.to eql({}) }
    end

    context "when a file doesn't exist" do
      subject { described_class.new(fixture_path('banana.rb'), 1).to_h }

      it { is_expected.to be_nil }
    end

    context "when a file has less than INTERVAL lines before start line" do
      subject { described_class.new(fixture_path('code.rb'), 1).to_h }

      it do
        is_expected.to(
          eq(
            1 => 'module Airbrake',
            2 => '  ##',
            # rubocop:disable Metrics/LineLength
            3 => '  # Represents a chunk of information that is meant to be either sent to',
            # rubocop:enable Metrics/LineLength
            4 => '  # Airbrake or ignored completely.'
          )
        )
      end
    end

    context "when a file has less than INTERVAL lines after end line" do
      subject { described_class.new(fixture_path('code.rb'), 221).to_h }

      it do
        is_expected.to(
          eq(
            218 => '      end',
            219 => '    end',
            220 => '  end',
            221 => 'end'
          )
        )
      end
    end

    context "when a file has less lines than a code hunk requests" do
      subject { described_class.new(fixture_path('short_file.rb'), 2).to_h }

      it do
        is_expected.to(
          eq(
            1 => 'module Banana',
            2 => '  attr_reader :bingo',
            3 => 'end'
          )
        )
      end
    end

    context "when a line location is in the middle of a file" do
      subject { described_class.new(fixture_path('code.rb'), 100).to_h }

      it do
        is_expected.to(
          eq(
            97 => '        else',
            98 => '          return json if json && json.bytesize <= MAX_NOTICE_SIZE',
            99 => '        end',
            100 => '',
            101 => '        break if truncate == 0',
            102 => '      end',
            103 => '    end'
          )
        )
      end
    end

    context "when a line exceeds the length limit" do
      subject { described_class.new(fixture_path('long_line.txt'), 1).to_h }

      it "strips the line" do
        expect(subject[1]).to eq('l' + 'o' * 196 + 'ng')
      end
    end
  end
end
