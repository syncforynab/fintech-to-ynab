class YNAB::BulkTransactionCreator
  def initialize(transactions, budget_id: nil, account_id: nil)
    @transactions = transactions
    @client = YNAB::Client.new(ENV['YNAB_ACCESS_TOKEN'], budget_id, account_id)
  end

  def create
    transactions_to_create = []

    @transactions.each do |transaction|
      payee_id = @client.lookup_payee_id(transaction[:payee_name])
      category_id = payee_id.present? ? @client.lookup_category_id(payee_id) : nil

      next if @client.is_duplicate_transaction?(payee_id, category_id, transaction[:date], transaction[:amount])

      transactions_to_create << {
        payee_name: transaction[:payee_name],
        payee_id: payee_id,
        category_id: category_id,
        amount: transaction[:amount],
        memo: transaction[:description],
        date: transaction[:date].to_date,
        cleared: !!transaction[:cleared] ? 'Cleared' : 'Uncleared'
      }
    end

    if transactions_to_create.any?
      @client.create_transactions(transactions_to_create)
    else
      :no_transactions_to_create
    end
  end
end
