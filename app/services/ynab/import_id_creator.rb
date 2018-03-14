class YNAB::ImportIdCreator
  def initialize
    @occurence = Hash.new
  end

  def prefill!(ynab_client, start_date = nil)
    ynab_client.transactions(since_date: start_date).each do |transaction|
      import_id(transaction.amount.to_i, transaction.date)
    end
  end

  def import_id(amount, date)
    key = ['YNAB', amount, date].join(':')
    @occurence[key] ||= 0
    @occurence[key] += 1
    key + ":#{@occurence[key]}"
  end
end
