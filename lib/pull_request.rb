require 'business_time'
BusinessTime::Config.beginning_of_workday = "9:30 am"
BusinessTime::Config.end_of_workday = "5:30 pm"
require 'status'
require 'time_formatter'
require 'terminal-table'

class PullRequest
  attr_reader :data
  attr_reader :github

  def initialize(data, github)
    @data = data
    @github = github
  end

  def inspect
    puts "title: #{data.title}"
    puts "state: #{state}"

    puts "number: #{data.number}"
    puts "head ref: #{data.head.ref}"
    puts "url: #{url}"

    puts "Work started: #{work_started}"
    if complete?
      puts "#{state} at #{completion_time}"
      puts "Elapsed time: #{elapsed_time}"
      puts "Elapsed time secs: #{elapsed_time_secs}"
    else
      puts "Not complete: #{state}"
    end

    build_start = build_triggering_events.size==1 ? build_triggering_events.first.created_at : nil
    if build_start
      puts "Build triggered at #{build_start}"
      time_start_from = build_start
    else
      puts "Found no triggering events, using work started time of #{work_started} instead"
      time_start_from = work_started
    end

    puts "Status checks:"
    grouped_statuses = statuses.group_by {|s| s.context}


    table = Terminal::Table.new(headings: ['Check', "URL", "Work start", "Build start", "Closed", "Time to pending", "Success", "Fail", "Error"]) do |t|
      statuses.group_by {|s| s.context}.each do |context, status_check_list|
        row_data = %w{pending success failure error}.map do |desired_state|
          status_check_list
            .select {|s| s.state == desired_state}
            .map {|s| s.created_at }
            .first
        end

        row = [context, url, work_started, build_start, completion_time] + row_data.map {|d| d ? (d - time_start_from).to_s : "" }
        t.add_row row
      end
    end

    puts table
  end

  def url
    data._links.html.href
  end

  class PushEvent
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def action
      ""
    end

    def type
      data.type
    end

    def ref
      data.payload.ref
    end

    def head
      data.payload.head
    end

    def created_at
      data.created_at
    end

    def related?(desired_ref, desired_sha)
      ref == "refs/heads/#{desired_ref}" && head == desired_sha
    end
  end

  class PullRequestEvent
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def type
      data.type
    end

    def ref
      data.payload.pull_request.head.ref
    end

    def head
      data.payload.pull_request.head.sha
    end

    def created_at
      data.created_at
    end

    def action
      data.payload.action
    end

    def related?(desired_ref, desired_sha)
      if %w{opened reopened synchronize}.include?(action)
        ref == desired_ref && head == desired_sha
      else
        false
      end
    end
  end

  def build_triggering_events(ref_override=nil, sha_override=nil)
    all_events = github.repository_events(user_repo, per_page:100)
    all_events = all_events
      .select { |e| %w{PushEvent PullRequestEvent}.include?(e.type) }
      .map { |e| e.type=='PushEvent' ? PushEvent.new(e) : PullRequestEvent.new(e) }

    all_events.select do |e| 
      e.related?(ref_override||ref, sha_override||sha)
    end
  end

  def is_related_pull_request_event?(e, ref,sha)
    # PR event types
    # opened, closed, reopened, assigned, 
    # unassigned, review_requested, review_request_removed, labeled, unlabeled, 
    # and synchronize.

    if e.type=='PullRequestEvent'
      if %w{opened reopened synchronize}.include?(e.payload.action)
        if e.payload.pull_request.head.ref == ref
          e.payload.pull_request.head.sha == sha
        else
          false
        end
      else
        false
      end
    else
      false
    end
  end

  def ref
    data.head.ref
  end

  def sha
    data.head.sha
  end

  def user_repo
    data.head.repo.full_name
  end

  def statuses
    github.statuses(user_repo, sha).map {|s| Status.new(s, github) }
  end

  def complete?
    state =='closed' || state == 'merged'
  end

  def completion_time
    data.merged_at || data.closed_at
  end

  def elapsed_time
    if complete?
      format_duration(work_started, completion_time)
    end
  end

  def elapsed_time_secs
    if complete?
      work_started.business_time_until(completion_time)
    end
  end

  def format_duration(start_time, end_time)
    TimeFormatter.new(start_time.business_time_until(end_time)).to_s
  end

  def state
    data.state
  end

  def commits
    @commits ||= github.pull_request_commits(data.head.repo.id, data.number, per_page: 100)
  end

  def work_started
    @work_started ||= [data.created_at, data.updated_at, earliest_commit_date].min
  end

  def earliest_commit_date
    commits.flat_map do |c|
      [
        c.commit.committer.date,
        c.commit.author.date
      ]
    end.min
  end

  def summarise_commit(c)
    short_sha = c.sha[0...6]
    initials = initials(c.commit.committer.name)
    date = format_date(c.commit.committer.date)
    date2 = format_date(c.commit.author.date)
    first_line = first_line(c.commit.message)

    puts "#{short_sha} #{initials} #{date} #{first_line}"
    puts "#{short_sha} #{initials} #{date2}"
  end

  def initials(full_name)
    i = full_name.split(/ +/).map {|n| n[0] }
    i.first + i.last
  end

  def format_date(date)
    date.to_s
  end

  def first_line(message)
    message.split("\n")[0]
  end
end
