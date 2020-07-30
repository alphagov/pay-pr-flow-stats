require 'pull_request'
require 'pp'
require 'time'
require 'date'
require 'json'
require 'sawyer'

RSpec.describe PullRequest do
  let(:sawyer_agent) { Sawyer::Agent.new("") }
  let(:data) { Sawyer::Resource.new(sawyer_agent, JSON.parse(File.read(File.dirname(__FILE__) + "/fixtures/one_pr.json"))) }
  let(:status_data) { 
    JSON.parse(File.read(File.dirname(__FILE__) + "/fixtures/statuses.json")).map { |status|
      Sawyer::Resource.new(sawyer_agent, status) 
    }
  }

  let(:events_data) { 
    JSON.parse(File.read(File.dirname(__FILE__) + "/fixtures/events.json")).map { |status|
      Sawyer::Resource.new(sawyer_agent, status) 
    }
  }

  #github.repository_events('alphagov/pay-connector', per_page:100)

  let(:github) { double("github", statuses: status_data, repository_events: events_data) }
  subject(:pr) { PullRequest.new(data, github) }

  it "works" do
    start_time_weekday = Time.local(2017, 03, 31, 9, 30, 0)
    end_time_weekday = Time.local(2017, 03, 31, 9, 31, 0)
    expect(pr.format_duration(start_time_weekday, end_time_weekday)).to eq("1 minute")

    start_time_weekday = Time.local(2017, 02, 23, 9, 30, 0)
    end_time_weekday = Time.local(2017, 02, 23, 9, 30, 5)
    expect(pr.format_duration(start_time_weekday, end_time_weekday)).to eq("5 seconds")

    start_time_fri_utc = Time.local(2017, 03, 24, 17, 30, 0)
    end_time_mon_dst = Time.local(2017, 03, 28, 9, 31, 0)
    expect(pr.format_duration(start_time_fri_utc, end_time_mon_dst)).to eq("1 working day 1 minute")

    start_time_fri_utc = Time.local(2017, 03, 24, 17, 30, 0)
    end_time_mon_dst = Time.local(2017, 03, 28, 10, 31, 0)
    expect(pr.format_duration(start_time_fri_utc, end_time_mon_dst)).to eq("1 working day 1 hour 1 minute")

    start_time_fri_utc = Time.local(2017, 03, 24, 17, 30, 0)
    end_time_mon_dst = Time.local(2017, 03, 28, 11, 31, 0)
    expect(pr.format_duration(start_time_fri_utc, end_time_mon_dst)).to eq("1 working day 2 hours 1 minute")
  end

  describe '#build_triggering_events' do
    it "gets build triggering events for PullRequestEvent" do
      expect(pr.build_triggering_events.size).to eq(1)
      expect(pr.build_triggering_events.map {|e| e.type}).to eq(["PullRequestEvent"])
      expect(pr.build_triggering_events.map {|e| e.action}).to eq(["opened"])
      expect(pr.build_triggering_events.map {|e| e.ref}).to eq(["PP-6353-get-metric-registry-correctly"])
      expect(pr.build_triggering_events.map {|e| e.head}).to eq(["c6455a223b2d75dbde08a689aa2285f6e24dd265"])
      expect(pr.build_triggering_events.map {|e| e.created_at}).to eq(["2020-07-29T15:44:19.000Z"])
    end

    it "gets build triggering events for PushEvents" do
      events = pr.build_triggering_events("PP-6353-log-payment-transition-to-hg", "d0f01ce3e7c5497bf51a0d706f768f0b393e6e79").select {|e| e.type=='PushEvent'}
      expect(events.size).to eq(1)
      expect(events.map {|e| e.head}).to eq([
        "d0f01ce3e7c5497bf51a0d706f768f0b393e6e79", 
      ])
      expect(events.map {|e| e.created_at}).to eq(["2020-07-29T13:39:15.000Z"])
    end
  end

  it "gets sha" do
    expect(pr.sha).to eq("c6455a223b2d75dbde08a689aa2285f6e24dd265")
  end

  it "gets user and repo" do
    expect(pr.user_repo).to eq("alphagov/pay-connector")
  end
  
  it "gets statuses" do
    expect(pr.statuses.size).to eq(13)
    s = pr.statuses.first

    expect(s.state).to eq("success")
    expect(s.description).to eq("Concourse CI build success")
    expect(s.target_url).to eq("https://cd.gds-reliability.engineering/builds/442871")
    expect(s.context).to eq("concourse-ci/card e2e tests")
    expect(s.created_at).to eq("2020-07-29T15:57:22.000Z")
    expect(s.updated_at).to eq("2020-07-29T15:57:22.000Z")
  end
end
