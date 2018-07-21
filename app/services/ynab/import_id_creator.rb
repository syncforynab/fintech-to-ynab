class YNAB::ImportIdCreator
  def initialize
    @occurence = Hash.new
  end

  def import_id(amount, date)
    key = ['YNAB', amount, date].join(':')
    @occurence[key] ||= 0
    @occurence[key] += 1
    key + ":#{@occurence[key]}"
  end
end
