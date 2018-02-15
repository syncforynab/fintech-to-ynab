class YNAB::BulkTransactionCreator
  def initialize(transactions, budget_id: nil, account_id: nil)
    @transactions = transactions
    @client = YNAB::Client.new(ENV['YNAB_ACCESS_TOKEN'], budget_id, account_id)
  end

  def create
    transactions_to_create = []

    @transactions.each do |transaction|
      transactions_to_create << {
        import_id: transaction[:id],
        payee_name: transaction[:payee_name],
        amount: transaction[:amount],
        memo: transaction[:description],
        date: transaction[:date].to_date,
        cleared: !!transaction[:cleared] ? 'Cleared' : 'Uncleared',
        flag: transaction[:flag]
      }
    end

    if transactions_to_create.any?
      @client.create_transactions(transactions_to_create)
    else
      :no_transactions_to_create
    end
  end
end
