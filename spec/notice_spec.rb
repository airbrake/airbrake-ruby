require 'spec_helper'

RSpec.describe Airbrake::Notice do
  let(:notice) do
    described_class.new(Airbrake::Config.new, AirbrakeTestError.new, bingo: '1')
  end

  describe "#new" do
    let(:params) do
      { bingo: 'bango', bongo: 'bish' }
    end

    let(:ex) { airbrake_exception_class.new(params) }

    context "given an exception class, which supports #to_airbrake" do
      context "and when #to_airbrake returns a non-Hash object" do
        let(:airbrake_exception_class) do
          Class.new(AirbrakeTestError) do
            def to_airbrake
              Object.new
            end
          end
        end

        it "rescues the error, logs it and doesn't modify the payload" do
          out = StringIO.new
          config = Airbrake::Config.new(logger: Logger.new(out))
          notice = nil

          expect { notice = described_class.new(config, ex) }.not_to raise_error
          expect(out.string).to match(/#to_airbrake failed:.+Object.+must be a Hash/)
          expect(notice[:params]).to be_empty
        end
      end

      context "and when #to_airbrake errors out" do
        let(:airbrake_exception_class) do
          Class.new(AirbrakeTestError) do
            def to_airbrake
              1 / 0
            end
          end
        end

        it "rescues the error, logs it and doesn't modify the payload" do
          out = StringIO.new
          config = Airbrake::Config.new(logger: Logger.new(out))
          notice = nil

          expect { notice = described_class.new(config, ex) }.not_to raise_error
          expect(out.string).to match(/#to_airbrake failed: ZeroDivisionError/)
          expect(notice[:params]).to be_empty
        end
      end

      context "and when #to_airbrake succeeds" do
        let(:airbrake_exception_class) do
          Class.new(AirbrakeTestError) do
            def initialize(params)
              @params = params
            end

            def to_airbrake
              { params: @params }
            end
          end
        end

        it "merges the parameters with the notice" do
          notice = described_class.new(Airbrake::Config.new, ex)
          expect(notice[:params]).to eq(params)
        end
      end
    end
  end

  describe "#to_json" do
    context "app_version" do
      context "when missing" do
        it "doesn't include app_version" do
          expect(notice.to_json).not_to match(/"context":{"version":"1.2.3"/)
        end
      end

      context "when present" do
        let(:config) do
          Airbrake::Config.new(app_version: '1.2.3', root_directory: '/one/two')
        end

        let(:notice) { described_class.new(config, AirbrakeTestError.new) }

        it "includes app_version" do
          expect(notice.to_json).to match(/"context":{"version":"1.2.3"/)
        end

        it "includes root_directory" do
          expect(notice.to_json).to match(%r{"rootDirectory":"/one/two"})
        end
      end
    end

    context "truncation" do
      shared_examples 'payloads' do |size, msg|
        it msg do
          ex = AirbrakeTestError.new

          backtrace = []
          size.times { backtrace << "bin/rails:3:in `<main>'" }
          ex.set_backtrace(backtrace)

          notice = described_class.new(Airbrake::Config.new, ex)

          expect(notice.to_json.bytesize).to be < 64000
        end
      end

      max_msg = 'truncates to the max allowed size'

      context "with an extremely huge payload" do
        include_examples 'payloads', 200_000, max_msg
      end

      context "with a big payload" do
        include_examples 'payloads', 50_000, max_msg
      end

      small_msg = "doesn't truncate it"

      context "with a small payload" do
        include_examples 'payloads', 1000, small_msg
      end

      context "with a tiny payload" do
        include_examples 'payloads', 300, small_msg
      end

      context "when truncation failed" do
        it "returns nil" do
          expect_any_instance_of(Airbrake::Truncator).
            to receive(:reduce_max_size).and_return(0)

          encoded = Base64.encode64("\xD3\xE6\xBC\x9D\xBA").encode!('ASCII-8BIT')
          bad_string = Base64.decode64(encoded)

          ex = AirbrakeTestError.new

          backtrace = []
          10.times { backtrace << "bin/rails:3:in `<#{bad_string}>'" }
          ex.set_backtrace(backtrace)

          config = Airbrake::Config.new(logger: Logger.new('/dev/null'))
          notice = described_class.new(config, ex)

          expect(notice.to_json).to be_nil
        end
      end

      describe "object replacement with its string version" do
        let(:klass) { Class.new {} }
        let(:ex) { AirbrakeTestError.new }
        let(:params) { { bingo: [Object.new, klass.new] } }
        let(:notice) { described_class.new(Airbrake::Config.new, ex, params) }

        before do
          backtrace = []
          backtrace_size.times { backtrace << "bin/rails:3:in `<main>'" }
          ex.set_backtrace(backtrace)
        end

        context "with payload within the limits" do
          let(:backtrace_size) { 1000 }

          it "doesn't happen" do
            expect(notice.to_json).
              to match(/bingo":\["#<Object:.+>","#<#<Class:.+>:.+>"/)
          end
        end

        context "with payload bigger than the limit" do
          context "with payload within the limits" do
            let(:backtrace_size) { 50_000 }

            it "happens" do
              expect(notice.to_json).
                to match(/bingo":\[".+Object.+",".+Class.+"/)
            end
          end
        end
      end
    end

    it "overwrites the 'notifier' payload with the default values" do
      notice[:notifier] = { name: 'bingo', bango: 'bongo' }

      expect(notice.to_json).
        to match(/"notifier":{"name":"airbrake-ruby","version":".+","url":".+"}/)
    end

    it "always contains context/hostname" do
      expect(notice.to_json).
        to match(/"context":{.*"hostname":".+".*}/)
    end

    it "defaults to the error severity" do
      expect(notice.to_json).to match(/"context":{.*"severity":"error".*}/)
    end
  end

  describe "#[]" do
    it "accesses payload" do
      expect(notice[:params]).to eq(bingo: '1')
    end

    it "raises error if notice is ignored" do
      notice.ignore!
      expect { notice[:params] }.
        to raise_error(Airbrake::Error, 'cannot access ignored notice')
    end
  end

  describe "#[]=" do
    it "sets a payload value" do
      hash = { bingo: 'bango' }
      notice[:params] = hash
      expect(notice[:params]).to equal(hash)
    end

    it "raises error if notice is ignored" do
      notice.ignore!
      expect { notice[:params] = {} }.
        to raise_error(Airbrake::Error, 'cannot access ignored notice')
    end

    it "raises error when trying to assign unrecognized key" do
      expect { notice[:bingo] = 1 }.
        to raise_error(Airbrake::Error, /:bingo is not recognized among/)
    end

    it "raises when setting non-hash objects as the value" do
      expect { notice[:params] = Object.new }.
        to raise_error(Airbrake::Error, 'Got Object value, wanted a Hash')
    end
  end

  describe "#stash" do
    it "returns a hash" do
      obj = Object.new
      notice.stash[:bingo_object] = obj
      expect(notice.stash[:bingo_object]).to eql(obj)
    end
  end
end
