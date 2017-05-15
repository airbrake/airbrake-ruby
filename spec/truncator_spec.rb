# coding: utf-8

require 'spec_helper'

RSpec.describe Airbrake::Truncator do
  let(:max_size) { 1000 }
  let(:truncated_len) { '[Truncated]'.length }
  let(:max_len) { max_size + truncated_len }

  before do
    @truncator = described_class.new(max_size)
  end

  describe "#truncate_object" do
    describe "error backtrace" do
      let(:error) do
        { type: 'AirbrakeTestError', message: 'App crashed!', backtrace: [] }
      end

      before do
        backtrace = Array.new(size) do
          { file: 'foo.rb', line: 23, function: '<main>' }
        end

        @error = error.merge(backtrace: backtrace)
        described_class.new(max_size).truncate_object(@error)
      end

      context "when long" do
        let(:size) { 2003 }

        it "truncates the backtrace to the max size" do
          expect(@error[:backtrace].size).to eq(1000)
        end
      end

      context "when short" do
        let(:size) { 999 }

        it "does not truncate the backtrace" do
          expect(@error[:backtrace].size).to eq(size)
        end
      end
    end

    describe "error message" do
      let(:error) do
        { type: 'AirbrakeTestError', message: 'App crashed!', backtrace: [] }
      end

      before do
        @error = error.merge(message: message)
        described_class.new(max_size).truncate_object(@error)
      end

      context "when long" do
        let(:message) { 'App crashed!' * 2000 }

        it "truncates the message" do
          expect(@error[:message].length).to eq(max_len)
        end
      end

      context "when short" do
        let(:message) { 'App crashed!' }
        let(:msg_len) { message.length }

        it "doesn't truncate the message" do
          expect(@error[:message].length).to eq(msg_len)
        end
      end
    end

    describe "given a hash with short values" do
      let(:params) do
        { bingo: 'bango', bongo: 'bish', bash: 'bosh' }
      end

      it "doesn't get truncated" do
        @truncator.truncate_object(params)
        expect(params).to eq(bingo: 'bango', bongo: 'bish', bash: 'bosh')
      end
    end

    describe "given a hash with a lot of elements" do
      context "the elements of which are also hashes with a lot of elements" do
        let(:params) do
          Hash[(0...4124).each_cons(2).to_a].tap do |h|
            h[0] = Hash[(0...4124).each_cons(2).to_a]
          end
        end

        it "truncates all the hashes to the max allowed size" do
          expect(params.size).to eq(4123)
          expect(params[0].size).to eq(4123)

          @truncator.truncate_object(params)

          expect(params.size).to eq(1000)
          expect(params[0].size).to eq(1000)
        end
      end
    end

    describe "given a set with a lot of elements" do
      context "the elements of which are also sets with a lot of elements" do
        let(:params) do
          row = (0...4124).each_cons(2)
          set = Set.new(row.to_a.unshift(row.to_a))
          { bingo: set }
        end

        it "truncates all the sets to the max allowed size" do
          expect(params[:bingo].size).to eq(4124)
          expect(params[:bingo].to_a[0].size).to eq(4123)

          @truncator.truncate_object(params)

          expect(params[:bingo].size).to eq(1000)
          expect(params[:bingo].to_a[0].size).to eq(1000)
        end
      end

      context "including recursive sets" do
        let(:params) do
          a = Set.new
          a << a << :bango
          { bingo: a }
        end

        it "prevents recursion" do
          @truncator.truncate_object(params)

          expect(params).to eq(bingo: Set.new(['[Circular]', :bango]))
        end
      end
    end

    describe "given an array with a lot of elements" do
      context "the elements of which are also arrays with a lot of elements" do
        let(:params) do
          row = (0...4124).each_cons(2)
          { bingo: row.to_a.unshift(row.to_a) }
        end

        it "truncates all the arrays to the max allowed size" do
          expect(params[:bingo].size).to eq(4124)
          expect(params[:bingo][0].size).to eq(4123)

          @truncator.truncate_object(params)

          expect(params[:bingo].size).to eq(1000)
          expect(params[:bingo][0].size).to eq(1000)
        end
      end
    end

    describe "given a hash with long values" do
      context "which are strings" do
        let(:params) do
          { bingo: 'bango' * 2000, bongo: 'bish', bash: 'bosh' * 1000 }
        end

        it "truncates only long strings" do
          expect(params[:bingo].length).to eq(10_000)
          expect(params[:bongo].length).to eq(4)
          expect(params[:bash].length).to eq(4000)

          @truncator.truncate_object(params)

          expect(params[:bingo].length).to eq(max_len)
          expect(params[:bongo].length).to eq(4)
          expect(params[:bash].length).to eq(max_len)
        end
      end

      context "which are arrays" do
        context "of long strings" do
          let(:params) do
            { bingo: ['foo', 'bango' * 2000, 'bar', 'piyo' * 2000, 'baz'],
              bongo: 'bish',
              bash: 'bosh' * 1000 }
          end

          it "truncates long strings in the array, but not short ones" do
            expect(params[:bingo].map(&:length)).to eq([3, 10_000, 3, 8_000, 3])
            expect(params[:bongo].length).to eq(4)
            expect(params[:bash].length).to eq(4000)

            @truncator.truncate_object(params)

            expect(params[:bingo].map(&:length)).to eq([3, max_len, 3, max_len, 3])
            expect(params[:bongo].length).to eq(4)
            expect(params[:bash].length).to eq(max_len)
          end
        end

        context "of short strings" do
          let(:params) do
            { bingo: %w[foo bar baz], bango: 'bongo', bish: 'bash' }
          end

          it "truncates long strings in the array, but not short ones" do
            @truncator.truncate_object(params)
            expect(params).
              to eq(bingo: %w[foo bar baz], bango: 'bongo', bish: 'bash')
          end
        end

        context "of hashes" do
          context "with long strings" do
            let(:params) do
              { bingo: [{}, { bango: 'bongo', hoge: { fuga: 'piyo' * 2000 } }],
                bish: 'bash',
                bosh: 'foo' }
            end

            it "truncates the long string" do
              expect(params[:bingo][1][:hoge][:fuga].length).to eq(8000)

              @truncator.truncate_object(params)

              expect(params[:bingo][0]).to eq({})
              expect(params[:bingo][1][:bango]).to eq('bongo')
              expect(params[:bingo][1][:hoge][:fuga].length).to eq(max_len)
              expect(params[:bish]).to eq('bash')
              expect(params[:bosh]).to eq('foo')
            end
          end

          context "with short strings" do
            let(:params) do
              { bingo: [{}, { bango: 'bongo', hoge: { fuga: 'piyo' } }],
                bish: 'bash',
                bosh: 'foo' }
            end

            it "doesn't truncate the short string" do
              expect(params[:bingo][1][:hoge][:fuga].length).to eq(4)

              @truncator.truncate_object(params)

              expect(params[:bingo][0]).to eq({})
              expect(params[:bingo][1][:bango]).to eq('bongo')
              expect(params[:bingo][1][:hoge][:fuga].length).to eq(4)
              expect(params[:bish]).to eq('bash')
              expect(params[:bosh]).to eq('foo')
            end
          end

          context "with strings that equal to max_size" do
            before do
              @truncator = described_class.new(max_size)
            end

            let(:params) { { unicode: '1111' } }
            let(:max_size) { params[:unicode].size }

            it "is doesn't truncate the string" do
              @truncator.truncate_object(params)

              expect(params[:unicode].length).to eq(max_size)
              expect(params[:unicode]).to match(/\A1{#{max_size}}\z/)
            end
          end
        end

        context "of recursive hashes" do
          let(:params) do
            a = { bingo: {} }
            a[:bingo][:bango] = a
          end

          it "prevents recursion" do
            @truncator.truncate_object(params)

            expect(params).to eq(bingo: { bango: '[Circular]' })
          end
        end

        context "of arrays" do
          context "with long strings" do
            let(:params) do
              { bingo: ['bango', ['bongo', ['bish' * 2000]]],
                bish: 'bash',
                bosh: 'foo' }
            end

            it "truncates only the long string" do
              expect(params[:bingo][1][1][0].length).to eq(8000)

              @truncator.truncate_object(params)

              expect(params[:bingo][1][1][0].length).to eq(max_len)
            end
          end
        end

        context "of recursive arrays" do
          let(:params) do
            a = []
            a << a << :bango
            { bingo: a }
          end

          it "prevents recursion" do
            @truncator.truncate_object(params)

            expect(params).to eq(bingo: ['[Circular]', :bango])
          end
        end
      end

      context "which are arbitrary objects" do
        context "with default #to_s" do
          let(:params) { { bingo: Object.new } }

          it "converts the object to a safe string" do
            @truncator.truncate_object(params)

            expect(params[:bingo]).to include('Object')
          end
        end

        context "with redefined #to_s" do
          let(:params) do
            obj = Object.new

            def obj.to_s
              'bango' * 2000
            end

            { bingo: obj }
          end

          it "truncates the string if it's too long" do
            @truncator.truncate_object(params)

            expect(params[:bingo].length).to eq(max_len)
          end
        end

        context "with other owner than Kernel" do
          let(:params) do
            mod = Module.new do
              def to_s
                "I am a fancy object" * 2000
              end
            end

            klass = Class.new { include mod }

            { bingo: klass.new }
          end

          it "truncates the string it if it's long" do
            @truncator.truncate_object(params)

            expect(params[:bingo].length).to eq(max_len)
          end
        end
      end

      context "multiple copies of the same object" do
        let(:params) do
          bingo = []
          bango = ['bongo']
          bingo << bango << bango
          { bish: bingo }
        end

        it "are not being truncated" do
          @truncator.truncate_object(params)

          expect(params).to eq(bish: [['bongo'], ['bongo']])
        end
      end
    end

    describe "unicode payload" do
      before do
        @truncator = described_class.new(max_size - 1)
      end

      describe "truncation" do
        let(:params) { { unicode: "€€€€" } }
        let(:max_size) { params[:unicode].length }

        it "is performed correctly" do
          @truncator.truncate_object(params)

          expect(params[:unicode].length).to eq(max_len - 1)
          expect(params[:unicode]).to match(/\A€{#{max_size - 1}}\[Truncated\]\z/)
        end
      end

      describe "string encoding conversion" do
        let(:params) { { unicode: "bad string€\xAE" } }
        let(:max_size) { 100 }

        it "converts strings to valid UTF-8" do
          @truncator.truncate_object(params)

          expect(params[:unicode]).to match(/\Abad string€[�\?]\z/)
          expect { params.to_json }.not_to raise_error
        end

        it "converts ASCII-8BIT strings with invalid characters to UTF-8 correctly" do
          # Shenanigans to get a bad ASCII-8BIT string. Direct conversion raises error.
          encoded = Base64.encode64("\xD3\xE6\xBC\x9D\xBA").encode!('ASCII-8BIT')
          bad_string = Base64.decode64(encoded)

          params = { unicode: bad_string }

          @truncator.truncate_object(params)

          expect(params[:unicode]).to match(/[�\?]{4}/)
        end

        it "doesn't fail when string is frozen" do
          encoded = Base64.encode64("\xD3\xE6\xBC\x9D\xBA").encode!('ASCII-8BIT')
          bad_string = Base64.decode64(encoded).freeze

          params = { unicode: bad_string }

          @truncator.truncate_object(params)

          expect(params[:unicode]).to match(/[�\?]{4}/)
        end
      end
    end

    describe "given a non-recursible object" do
      it "raises error" do
        expect { @truncator.truncate_object(:bingo) }.
          to raise_error(Airbrake::Error, /cannot truncate object/)
      end
    end
  end
end
