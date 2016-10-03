require 'spec_helper'

RSpec.describe "Airbrake::Notifier whitelist_keys" do
  def expect_a_request_with_body(body)
    expect(a_request(:post, endpoint).with(body: body)).to have_been_made.once
  end

  let(:project_id) { 105138 }
  let(:project_key) { 'fd04e13d806a90f96614ad8e529b2822' }
  let(:localhost) { 'http://localhost:8080' }

  let(:endpoint) do
    "https://airbrake.io/api/v3/projects/#{project_id}/notices?key=#{project_key}"
  end

  let(:airbrake_params) do
    { project_id: project_id,
      project_key: project_key,
      logger: Logger.new(StringIO.new) }
  end

  let(:ex) { AirbrakeTestError.new }

  shared_examples 'whitelisting' do |keys, params|
    it "filters everything but the value of the specified key" do
      whitelist = { whitelist_keys: keys }
      notifier = Airbrake::Notifier.new(airbrake_params.merge(whitelist))

      notifier.notify_sync(ex, params)

      expect_a_request_with_body(expected_body)
    end
  end

  shared_examples 'logging' do |keys, params|
    it "logs the error" do
      out = StringIO.new
      whitelist = { whitelist_keys: keys, logger: Logger.new(out) }
      notifier = Airbrake::Notifier.new(airbrake_params.merge(whitelist))

      notifier.notify_sync(ex, params)

      expect(out.string).to match(expected_output)
    end
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  context "when whitelisting with a Regexp" do
    let(:expected_body) do
      /"params":{"bingo":"bango","bongo":"\[Filtered\]","bash":"\[Filtered\]"}/
    end

    include_examples(
      'whitelisting',
      [/\Abin/],
      bingo: 'bango', bongo: 'bish', bash: 'bosh'
    )
  end

  context "when whitelisting with a Symbol" do
    let(:expected_body) do
      /"params":{"bingo":"\[Filtered\]","bongo":"bish","bash":"\[Filtered\]"}/
    end

    include_examples(
      'whitelisting',
      [:bongo],
      bingo: 'bango', bongo: 'bish', bash: 'bosh'
    )
  end

  context "when whitelisting with a String" do
    let(:expected_body) do
      /"params":{"bingo":"\[Filtered\]","bongo":"\[Filtered\]",
         "bash":"bosh","bbashh":"\[Filtered\]"}/x
    end

    include_examples(
      'whitelisting',
      ['bash'],
      bingo: 'bango', bongo: 'bish', bash: 'bosh', bbashh: 'bboshh'
    )
  end

  context "when payload has a hash" do
    context "and it is a non-recursive hash" do
      let(:expected_body) { /"params":{"bingo":"\[Filtered\]","bongo":{"bish":"bash"}}/ }

      include_examples(
        'whitelisting',
        %w(bongo bish),
        bingo: 'bango', bongo: { bish: 'bash' }
      )
    end

    context "and it is a recursive hash" do
      it "errors when nested hashes are not filtered" do
        whitelist = airbrake_params.merge(whitelist_keys: %w(bingo bango))
        notifier = Airbrake::Notifier.new(whitelist)

        bongo = { bingo: {} }
        bongo[:bingo][:bango] = bongo

        if RUBY_ENGINE == 'jruby'
          # JRuby might raise two different exceptions, which represent the
          # same thing. One is a Java exception, the other is a Ruby
          # exception. It's probably a JRuby bug:
          # https://github.com/jruby/jruby/issues/1903
          begin
            expect do
              notifier.notify_sync(ex, bongo)
            end.to raise_error(SystemStackError)
          rescue RSpec::Expectations::ExpectationNotMetError
            expect do
              notifier.notify_sync(ex, bongo)
            end.to raise_error(java.lang.StackOverflowError)
          end
        else
          expect do
            notifier.notify_sync(ex, bongo)
          end.to raise_error(SystemStackError)
        end
      end
    end
  end

  context "when there was a proc provided, which returns an array of keys" do
    let(:expected_body) do
      /"params":{"bingo":"\[Filtered\]","bongo":"bish","bash":"\[Filtered\]"}/
    end

    include_examples(
      'whitelisting',
      [proc { 'bongo' }],
      bingo: 'bango', bongo: 'bish', bash: 'bosh'
    )
  end

  context "when there was a proc provided along with normal keys" do
    let(:expected_body) do
      /"params":{"bingo":"\[Filtered\]","bongo":"bish","bash":"bosh"}/
    end

    include_examples(
      'whitelisting',
      [proc { 'bongo' }, :bash],
      bingo: 'bango', bongo: 'bish', bash: 'bosh'
    )
  end

  context "when there was a proc provided, which returns another proc" do
    context "when called once" do
      let(:expected_output) do
        /ERROR.+KeysWhitelist is invalid.+patterns: \[#<Proc:.+>\]/
      end

      include_examples('logging', [proc { proc { ['bingo'] } }], bingo: 'bango')
    end

    context "when called twice" do
      it "unwinds procs and filters keys" do
        whitelist = { whitelist_keys: [proc { proc { ['bingo'] } }] }
        notifier = Airbrake::Notifier.new(airbrake_params.merge(whitelist))

        notifier.notify_sync(ex, bingo: 'bango', bongo: 'bish')
        notifier.notify_sync(ex, bingo: 'bango', bongo: 'bish')

        expect_a_request_with_body(
          /"params":{"bingo":"bango","bongo":"\[Filtered\]"}/
        )
      end
    end
  end

  context "when there was a proc provided, which doesn't return an array of keys" do
    let(:expected_output) do
      /ERROR.+KeysWhitelist is invalid.+patterns: \[#<Object:.+>\]/
    end

    include_examples('logging', [proc { Object.new }], bingo: 'bango')

    it "doesn't whitelist keys" do
      whitelist = { whitelist_keys: [proc { Object.new }] }
      notifier = Airbrake::Notifier.new(airbrake_params.merge(whitelist))

      notifier.notify_sync(ex, bingo: 'bango', bongo: 'bish')

      expect_a_request_with_body(
        /"params":{"bingo":"\[Filtered\]","bongo":"\[Filtered\]"}/
      )
    end
  end

  describe "context/url" do
    let(:notifier) do
      Airbrake::Notifier.new(airbrake_params.merge(whitelist_keys: %w(bish)))
    end

    context "given a standard URL" do
      it "filters query parameters correctly" do
        notice = notifier.build_notice(ex)
        notice[:context][:url] = 'http://localhost:3000/crash?foo=bar&baz=bongo&bish=bash'

        notifier.notify_sync(notice)

        expect_a_request_with_body(
          # rubocop:disable Metrics/LineLength
          %r("context":{.*"url":"http://localhost:3000/crash\?foo=\[Filtered\]&baz=\[Filtered\]&bish=bash".*})
          # rubocop:enable Metrics/LineLength
        )
      end
    end

    context "given a non-standard URL" do
      it "leaves the URL unfiltered" do
        notice = notifier.build_notice(ex)
        notice[:context][:url] =
          'http://localhost:3000/cra]]]sh?foo=bar&baz=bongo&bish=bash'

        notifier.notify_sync(notice)

        expect_a_request_with_body(
          # rubocop:disable Metrics/LineLength
          %r("context":{.*"url":"http://localhost:3000/cra\]\]\]sh\?foo=bar&baz=bongo&bish=bash".*})
          # rubocop:enable Metrics/LineLength
        )
      end
    end

    context "given a URL without a query" do
      it "skips params filtering and leaves the URL untouched" do
        notice = notifier.build_notice(ex)
        notice[:context][:url] = 'http://localhost:3000/crash'

        notifier.notify_sync(notice)

        expect_a_request_with_body(
          %r("context":{.*"url":"http://localhost:3000/crash".*})
        )
      end
    end
  end
end
