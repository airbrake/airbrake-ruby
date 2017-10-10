require 'spec_helper'

RSpec.describe Airbrake::CodeHunk do
  let(:config) { Airbrake::Config.new }

  describe "#to_h" do
    context "when a file is empty" do
      subject { described_class.new(config).get(fixture_path('empty_file.rb'), 1) }

      it { is_expected.to eq(1 => '') }
    end

    context "when a file doesn't exist" do
      subject { described_class.new(config).get(fixture_path('banana.rb'), 1) }

      it { is_expected.to be_nil }
    end

    context "when a file has less than NLINES lines before start line" do
      subject { described_class.new(config).get(fixture_path('code.rb'), 1) }

      it do
        is_expected.to(
          eq(
            1 => 'module Airbrake',
            2 => '  ##',
            # rubocop:disable Metrics/LineLength
            3 => '  # Represents a chunk of information that is meant to be either sent to',
            # rubocop:enable Metrics/LineLength
          )
        )
      end
    end

    context "when a file has less than NLINES lines after end line" do
      subject { described_class.new(config).get(fixture_path('code.rb'), 222) }

      it do
        is_expected.to(
          eq(
            220 => '  end',
            221 => 'end'
          )
        )
      end
    end

    context "when a file has less than NLINES lines before and after" do
      subject { described_class.new(config).get(fixture_path('short_file.rb'), 2) }

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

    context "when a file has enough lines before and after" do
      subject { described_class.new(config).get(fixture_path('code.rb'), 100) }

      it do
        is_expected.to(
          eq(
            98 => '          return json if json && json.bytesize <= MAX_NOTICE_SIZE',
            99 => '        end',
            100 => '',
            101 => '        break if truncate == 0',
            102 => '      end'
          )
        )
      end
    end

    context "when a line exceeds the length limit" do
      subject { described_class.new(config).get(fixture_path('long_line.txt'), 1) }

      it "strips the line" do
        expect(subject[1]).to eq('l' + 'o' * 196 + 'ng')
      end
    end

    context "when an error occurrs while fetching code" do
      before do
        expect(File).to receive(:foreach).and_raise(Errno::EACCES)
      end

      it "logs error and returns nil" do
        out = StringIO.new
        config = Airbrake::Config.new
        config.logger = Logger.new(out)
        expect(described_class.new(config).get(fixture_path('code.rb'), 1)).to(
          eq(1 => '')
        )
        expect(out.string).to match(/can't read code hunk.+Permission denied/)
      end
    end
  end
end
