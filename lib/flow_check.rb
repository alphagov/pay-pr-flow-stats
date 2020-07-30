require 'octokit'
require 'pp'
require 'logger'
require 'pry'

require 'pull_request'

class FlowCheck
  attr_accessor :api_token
  attr_reader :logger

  def initialize(env = ENV, logger: Logger.new(nil))
    @env = env
    @logger = logger
    @api_token = fetch_env("GITHUB_API_TOKEN")
  end

  def call(argv)
    prs = github.pull_requests('alphagov/pay-connector', state: 'all')
    prs.take(20)
      .map {|data| PullRequest.new(data, github) }
      .each do |pr|
      pr.inspect

      puts "\n\n"
    end
  end

  def list_all_pay_repos
    repos = github.search_repositories('user:alphagov pay-', per_page: 100)
    logger.debug "Found #{repos[:total_count]} matching repos"
    logger.debug "Listing #{repos[:items].size} results"
    repos[:items]
  end

  def github
    @github ||= Octokit::Client.new(:access_token => api_token)
  end

private
  def fetch_env(name)
    @env.fetch(name)
  rescue KeyError
    raise "Environment variable #{name} required"
  end
end
