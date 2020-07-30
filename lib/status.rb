class Status
  attr_reader :data, :github

  def initialize(data, github)
    @data = data
    @github = github
  end

  def state
    data.state
  end

  def description
    data.description
  end

  def target_url
    data.target_url
  end

  def context
    data.context
  end

  def created_at
    data.created_at
  end

  def updated_at
    data.updated_at
  end
end