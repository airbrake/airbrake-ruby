require 'spec_helper'

RSpec.describe Airbrake::Notice do
  let(:notice) do
    described_class.new(Airbrake::Config.new, AirbrakeTestError.new, bingo: '1')
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
          expect_any_instance_of(Airbrake::PayloadTruncator).
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
end
