class YNAB::ImportIdCreator
  def initialize
    @occurence ||= Hash.new
  end

  def import_id(amount, date)
    key = ['Fintech-To-YNAB', amount, date].join(':')
    @occurence ||= Hash.new
    @occurence[key] ||= 0
    @occurence[key] += 1
    key + ":#{@occurence[key]}"
  end
end
