RSpec.describe Airbrake::CodeHunk do
  subject(:code_hunk) { described_class.new }

  after do
    %w[empty_file.rb code.rb banana.rb short_file.rb long_line.txt].each do |f|
      Airbrake::FileCache[project_root_path(f)] = nil
    end
  end

  describe "#to_h" do
    context "when file is empty" do
      subject do
        described_class.new.get(project_root_path('empty_file.rb'), 1)
      end

      it { is_expected.to eq(1 => '') }
    end

    context "when line is nil" do
      subject { described_class.new.get(project_root_path('code.rb'), nil) }

      it { is_expected.to be_nil }
    end

    context "when a file doesn't exist" do
      subject { described_class.new.get(project_root_path('banana.rb'), 1) }

      it { is_expected.to be_nil }
    end

    context "when a file has less than NLINES lines before start line" do
      subject(:code_hunk) do
        described_class.new.get(project_root_path('code.rb'), 1)
      end

      it do
        expect(code_hunk).to(
          eq(
            1 => 'module Airbrake',
            2 => '  ##',
            # rubocop:disable Layout/LineLength
            3 => '  # Represents a chunk of information that is meant to be either sent to',
            # rubocop:enable Layout/LineLength
          ),
        )
      end
    end

    context "when a file has less than NLINES lines after end line" do
      subject(:code_hunk) do
        described_class.new.get(project_root_path('code.rb'), 222)
      end

      it do
        expect(code_hunk).to(
          eq(
            220 => '  end',
            221 => 'end',
          ),
        )
      end
    end

    context "when a file has less than NLINES lines before and after" do
      subject(:code_hunk) do
        described_class.new.get(project_root_path('short_file.rb'), 2)
      end

      it do
        expect(code_hunk).to(
          eq(
            1 => 'module Banana',
            2 => '  attr_reader :bingo',
            3 => 'end',
          ),
        )
      end
    end

    context "when a file has enough lines before and after" do
      subject(:code_hunk) do
        described_class.new.get(project_root_path('code.rb'), 100)
      end

      it do
        expect(code_hunk).to(
          eq(
            98 => '          return json if json && json.bytesize <= MAX_NOTICE_SIZE',
            99 => '        end',
            100 => '',
            101 => '        break if truncate == 0',
            102 => '      end',
          ),
        )
      end
    end

    context "when a line exceeds the length limit" do
      subject(:code_hunk) do
        described_class.new.get(project_root_path('long_line.txt'), 1)
      end

      it "strips the line" do
        expect(code_hunk[1]).to eq("l#{'o' * 196}ng")
      end
    end

    context "when an error occurrs while fetching code" do
      before do
        allow(Airbrake::Loggable.instance).to receive(:error)
        allow(Airbrake::FileCache).to receive(:[]).and_raise(Errno::EACCES)
      end

      it "logs error and returns nil" do
        expect(code_hunk.get(project_root_path('code.rb'), 1)).to(
          eq(1 => ''),
        )
        expect(Airbrake::Loggable.instance).to have_received(:error).with(
          /can't read code hunk.+Permission denied/,
        )
      end
    end
  end
end
