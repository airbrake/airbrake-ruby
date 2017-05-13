require 'spec_helper'

RSpec.describe Airbrake::Filters::KeysWhitelist do
  subject { described_class.new(Logger.new('/dev/null'), patterns) }

  let(:notice) do
    Airbrake::Notice.new(Airbrake::Config.new, AirbrakeTestError.new)
  end

  shared_examples 'pattern matching' do |patts, params|
    let(:patterns) { patts }

    it "filters out the matching values" do
      notice[:params] = params.first
      subject.call(notice)
      expect(notice[:params]).to eq(params.last)
    end
  end

  context "when a pattern is a Regexp" do
    include_examples(
      'pattern matching',
      [/\Abin/],
      [
        { bingo: 'bango', bongo: 'bish', bash: 'bosh' },
        { bingo: 'bango', bongo: '[Filtered]', bash: '[Filtered]' }
      ]
    )
  end

  context "when a pattern is a Symbol" do
    include_examples(
      'pattern matching',
      [:bongo],
      [
        { bongo: 'bish', bash: 'bosh', bbashh: 'bboshh' },
        { bongo: 'bish', bash: '[Filtered]', bbashh: '[Filtered]' }
      ]
    )
  end

  context "when a pattern is a String" do
    include_examples(
      'pattern matching',
      ['bash'],
      [
        { bingo: 'bango', bongo: 'bish', bash: 'bosh' },
        { bingo: '[Filtered]', bongo: '[Filtered]', bash: 'bosh' }
      ]
    )
  end

  context "when a Proc pattern was provided" do
    context "along with normal keys" do
      include_examples(
        'pattern matching',
        [proc { 'bongo' }, :bash],
        [
          { bingo: 'bango', bongo: 'bish', bash: 'bosh' },
          { bingo: '[Filtered]', bongo: 'bish', bash: 'bosh' }
        ]
      )
    end

    context "which doesn't return an array of keys" do
      include_examples(
        'pattern matching',
        [proc { Object.new }],
        [
          { bingo: 'bango', bongo: 'bish', bash: 'bosh' },
          { bingo: '[Filtered]', bongo: '[Filtered]', bash: '[Filtered]' }
        ]
      )

      it "logs an error" do
        out = StringIO.new
        logger = Logger.new(out)
        keys_whitelist = described_class.new(logger, patterns)
        keys_whitelist.call(notice)

        expect(out.string).to(
          match(/ERROR.+KeysWhitelist is invalid.+patterns: \[#<Object:.+>\]/)
        )
      end
    end

    context "which returns another Proc" do
      let(:patterns) { [proc { proc { ['bingo'] } }] }

      context "and when the filter is called once" do
        it "logs an error" do
          out = StringIO.new
          logger = Logger.new(out)
          keys_whitelist = described_class.new(logger, patterns)
          keys_whitelist.call(notice)

          expect(out.string).to(
            match(/ERROR.+KeysWhitelist is invalid.+patterns: \[#<Proc:.+>\]/)
          )
        end

        include_examples(
          'pattern matching',
          [proc { proc { ['bingo'] } }],
          [
            { bingo: 'bango', bongo: 'bish', bash: 'bosh' },
            { bingo: '[Filtered]', bongo: '[Filtered]', bash: '[Filtered]' }
          ]
        )
      end
    end
  end

  context "when a pattern is invalid" do
    include_examples(
      'pattern matching',
      [Object.new],
      [
        { bingo: 'bango', bongo: 'bish', bash: 'bosh' },
        { bingo: '[Filtered]', bongo: '[Filtered]', bash: '[Filtered]' }
      ]
    )

    it "logs an error" do
      out = StringIO.new
      logger = Logger.new(out)
      keys_whitelist = described_class.new(logger, patterns)
      keys_whitelist.call(notice)

      expect(out.string).to(
        match(/ERROR.+KeysWhitelist is invalid.+patterns: \[#<Object:.+>\]/)
      )
    end
  end

  context "when a value contains a nested hash" do
    context "and it is non-recursive" do
      include_examples(
        'pattern matching',
        %w[bongo bish],
        [
          { bingo: 'bango', bongo: { bish: 'bash' } },
          { bingo: '[Filtered]', bongo: { bish: 'bash' } }
        ]
      )
    end

    context "and it is recursive" do
      let(:patterns) { %w[bingo bango] }

      it "errors when nested hashes are not filtered" do
        bongo = { bingo: {} }
        bongo[:bingo][:bango] = bongo
        notice[:params] = bongo

        if RUBY_ENGINE == 'jruby'
          # JRuby might raise two different exceptions, which represent the
          # same thing. One is a Java exception, the other is a Ruby
          # exception. It's probably a JRuby bug:
          # https://github.com/jruby/jruby/issues/1903
          begin
            expect do
              subject.call(notice)
            end.to raise_error(SystemStackError)
          rescue RSpec::Expectations::ExpectationNotMetError
            expect do
              subject.call(notice)
            end.to raise_error(java.lang.StackOverflowError)
          end
        else
          expect do
            subject.call(notice)
          end.to raise_error(SystemStackError)
        end
      end
    end
  end

  describe "context payload" do
    describe "URL" do
      let(:patterns) { ['bish'] }

      context "when it contains query params" do
        it "filters the params" do
          notice[:context][:url] = 'http://localhost:3000/crash?foo=bar&baz=bongo&bish=bash'
          subject.call(notice)
          expect(notice[:context][:url]).to(
            eq('http://localhost:3000/crash?foo=[Filtered]&baz=[Filtered]&bish=bash')
          )
        end
      end

      context "when it is invalid" do
        it "leaves the URL unfiltered" do
          notice[:context][:url] =
            'http://localhost:3000/cra]]]sh?foo=bar&baz=bongo&bish=bash'
          subject.call(notice)
          expect(notice[:context][:url]).to(
            eq('http://localhost:3000/cra]]]sh?foo=bar&baz=bongo&bish=bash')
          )
        end
      end

      context "when it is without a query" do
        it "leaves the URL untouched" do
          notice[:context][:url] = 'http://localhost:3000/crash'
          subject.call(notice)
          expect(notice[:context][:url]).to(eq('http://localhost:3000/crash'))
        end
      end
    end
  end
end
