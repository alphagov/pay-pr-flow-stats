require 'octokit'
require 'pp'
require 'logger'
require 'pry'
require 'socket'

require 'pull_request'

class FlowCheck
  attr_accessor :api_token
  attr_reader :logger

  def initialize(env = ENV, logger: Logger.new(nil))
    @env = env
    @logger = logger
    @api_token = fetch_env("GITHUB_API_TOKEN")
  end

  def call(args, options)
    if options[:pr_number] && options[:repo_name]
      github_prs = [ github.pull_request(options[:repo_name], options[:pr_number]) ]
    else
      github_prs = github.pull_requests('alphagov/pay-connector', state: 'all').take(20)
    end

    prs = github_prs.map {|data| PullRequest.new(data, github) }

    if options[:filter_manually_triggered]
      prs = prs.select{|pr| !pr.was_manually_retriggered}
    end

    if options[:quiet]
      prs
        .each do |pr|
          if pr.data.merged_at
            puts "PR ##{pr.data.number} has been merged -- skipping"
            next
          end

          total_elapsed_time = pr.total_elapsed_time
          pr_number = pr.data.number
          app_name = options[:repo_name].match(/.*\/pay-(.*)/i).captures[0]

          if options[:send]
            @hosted_graphite_api_token = fetch_env("HOSTED_GRAPHITE_API_TOKEN")
            @hosted_graphite_account_id = fetch_env("HOSTED_GRAPHITE_ACCOUNT_ID")
            metric_name_repo = "ci.concourse.pr.#{app_name}.build_time.success.duration"
            metric_name_standard = "ci.concourse.pr.build_time.success.duration"
            conn = TCPSocket.new "#{@hosted_graphite_account_id}.carbon.hostedgraphite.com", 2003
            conn.puts "#{@hosted_graphite_api_token}.#{metric_name_repo} #{total_elapsed_time}\n"
            conn.puts "#{@hosted_graphite_api_token}.#{metric_name_standard} #{total_elapsed_time}\n"
            puts "sent #{metric_name_repo} #{total_elapsed_time}"
            puts "sent #{metric_name_standard} #{total_elapsed_time}"
            conn.close
          else
            puts total_elapsed_time
          end
        end
    else
      prs
        .each do |pr|
        pr.inspect

        puts "\n\n"
      end
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
