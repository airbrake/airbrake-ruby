require 'spec_helper'

RSpec.describe "Airbrake::Notifier blacklist_keys" do
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

  shared_examples 'blacklisting' do |keys, params|
    it "filters out the value" do
      blacklist = { blacklist_keys: keys }
      notifier = Airbrake::Notifier.new(airbrake_params.merge(blacklist))

      notifier.notify_sync(ex, params)

      expect_a_request_with_body(expected_body)
    end
  end

  shared_examples 'logging' do |keys, params|
    it "logs the error" do
      out = StringIO.new
      blacklist = { blacklist_keys: keys, logger: Logger.new(out) }
      notifier = Airbrake::Notifier.new(airbrake_params.merge(blacklist))

      notifier.notify_sync(ex, params)

      expect(out.string).to match(expected_output)
    end
  end

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')
  end

  context "when blacklisting with a Regexp" do
    let(:expected_body) { /"params":{"bingo":"\[Filtered\]"}/ }
    include_examples('blacklisting', [/\Abin/], bingo: 'bango')
  end

  context "when blacklisting with a Symbol" do
    let(:expected_body) { /"params":{"bingo":"\[Filtered\]"}/ }
    include_examples('blacklisting', [:bingo], bingo: 'bango')
  end

  context "when blacklisting with a String" do
    let(:expected_body) { /"params":{"bingo":"\[Filtered\]"}/ }
    include_examples('blacklisting', ['bingo'], bingo: 'bango')
  end

  context "when payload has a hash" do
    context "and it is a non-recursive hash" do
      let(:expected_body) { /"params":{"bongo":{"bish":"\[Filtered\]"}}/ }
      include_examples('blacklisting', ['bish'], bongo: { bish: 'bash' })
    end

    context "and it is a recursive hash" do
      let(:expected_body) { /"params":{"bingo":{"bango":"\[Filtered\]"}}/ }

      bongo = { bingo: {} }
      bongo[:bingo][:bango] = bongo

      include_examples('blacklisting', ['bango'], bongo)
    end
  end

  context "when there was invalid pattern provided" do
    let(:expected_output) do
      /ERROR.+KeysBlacklist is invalid.+patterns: \[#<Object:.+>\]/
    end

    include_examples('logging', [Object.new], bingo: 'bango')
  end

  context "when there was a proc provided, which returns an array of keys" do
    let(:expected_body) { /"params":{"bingo":"\[Filtered\]","bongo":"bish"}/ }
    include_examples('blacklisting', [proc { 'bingo' }], bingo: 'bango', bongo: 'bish')
  end

  context "when there was a proc provided along with normal keys" do
    let(:expected_body) do
      /"params":{"bingo":"bango","bongo":"\[Filtered\]","bash":"\[Filtered\]"}/
    end

    include_examples(
      'blacklisting',
      [proc { 'bongo' }, :bash],
      bingo: 'bango', bongo: 'bish', bash: 'bosh'
    )
  end

  context "when there was a proc provided, which doesn't return an array of keys" do
    let(:expected_output) do
      /ERROR.+KeysBlacklist is invalid.+patterns: \[#<Object:.+>\]/
    end

    include_examples('logging', [proc { Object.new }], bingo: 'bango')

    it "doesn't blacklist keys" do
      blacklist = { blacklist_keys: [proc { Object.new }] }
      notifier = Airbrake::Notifier.new(airbrake_params.merge(blacklist))

      notifier.notify_sync(ex, bingo: 'bango', bongo: 'bish')

      expect_a_request_with_body(/"params":{"bingo":"bango","bongo":"bish"}/)
    end
  end

  context "when there was a proc provided, which returns another proc" do
    context "when called once" do
      let(:expected_output) do
        /ERROR.+KeysBlacklist is invalid.+patterns: \[#<Proc:.+>\]/
      end

      include_examples('logging', [proc { proc { ['bingo'] } }], bingo: 'bango')
    end

    context "when called twice" do
      it "unwinds procs and filters keys" do
        blacklist = { blacklist_keys: [proc { proc { ['bingo'] } }] }
        notifier = Airbrake::Notifier.new(airbrake_params.merge(blacklist))

        notifier.notify_sync(ex, bingo: 'bango', bongo: 'bish')
        notifier.notify_sync(ex, bingo: 'bango', bongo: 'bish')

        expect_a_request_with_body(
          /"params":{"bingo":"\[Filtered\]","bongo":"bish"}/
        )
      end
    end
  end

  it "filters query parameters correctly" do
    blacklist = { blacklist_keys: ['bish'] }
    notifier = Airbrake::Notifier.new(airbrake_params.merge(blacklist))

    notice = notifier.build_notice(ex)
    notice[:context][:url] = 'http://localhost:3000/crash?foo=bar&baz=bongo&bish=bash&color=%23FFAAFF'

    notifier.notify_sync(notice)

    # rubocop:disable Metrics/LineLength
    expected_body =
      %r("context":{.*"url":"http://localhost:3000/crash\?foo=bar&baz=bongo&bish=\[Filtered\]&color=%23FFAAFF".*})
    # rubocop:enable Metrics/LineLength

    expect_a_request_with_body(expected_body)
  end

  context "when the user payload is present" do
    context "and when the user key is ignored" do
      it "filters out user entirely" do
        blacklist = { blacklist_keys: ['user'] }
        notifier = Airbrake::Notifier.new(airbrake_params.merge(blacklist))

        notice = notifier.build_notice(ex)
        notice[:context][:user] = { id: 1337, name: 'Bingo Bango' }

        notifier.notify_sync(notice)

        expect_a_request_with_body(/"user":"\[Filtered\]"/)
      end
    end

    it "filters out individual user fields" do
      blacklist = { blacklist_keys: ['name'] }
      notifier = Airbrake::Notifier.new(airbrake_params.merge(blacklist))

      notice = notifier.build_notice(ex)
      notice[:context][:user] = { id: 1337, name: 'Bingo Bango' }

      notifier.notify_sync(notice)

      expect_a_request_with_body(/"user":{"id":1337,"name":"\[Filtered\]"}/)
    end
  end
end
