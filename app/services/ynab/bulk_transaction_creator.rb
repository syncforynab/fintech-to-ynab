class YNAB::BulkTransactionCreator
  def initialize(transactions, budget_id: nil, account_id: nil)
    @transactions = transactions

    @client = YNAB::Client.new(ENV['YNAB_ACCESS_TOKEN'], budget_id, account_id)
  end

  def create
    transactions_to_create = []

    @transactions.each do |transaction|
      payee_id = lookup_payee_id(transaction[:payee_name])
      category_id = payee_id.present? ? lookup_category_id(payee_id) : nil

      next if is_duplicate_transaction?(payee_id, category_id, transaction[:date], transaction[:amount])

      # @note Until YNAB has the ability to create payees, lets pass the payee_name to the description for now.
      transaction[:description] ||= ''
      transaction[:description] << " (#{transaction[:payee_name]})" if payee_id.nil?

      transactions_to_create << {
        payee_name: transaction[:payee_name],
        payee_id: payee_id,
        category_id: category_id,
        account_id: @client.selected_account_id,
        amount: transaction[:amount],
        memo: transaction[:description],
        date: transaction[:date].to_date,
        cleared: !!transaction[:cleared] ? 'Cleared' : 'Uncleared'
      }
    end

    if transactions_to_create.any?
      @client.create_transactions(@client.selected_budget_id, transactions_to_create)
    else
      :no_transactions_to_create
    end
  end

  private

  def is_duplicate_transaction?(payee_id, category_id, date, amount)
    transactions.any? do |transaction|
      transaction[:date] == date.to_date.to_s &&
        transaction[:amount] == amount &&
        transaction[:payee_id] == payee_id &&
        transaction[:category_id] == category_id
    end
  end

  def lookup_category_id(payee_id)
    transactions.select{|a| a[:payee_id] == payee_id }.last.try(:[], :category_id)
  end

  def lookup_payee_id(payee_name)
    payees.select{|p| p[:name].downcase == payee_name.to_s.downcase }.first.try(:[], :id)
  end

  def payees
    @_payees ||= @client.payees(@client.selected_budget_id)
  end

  def transactions
    @_transactions ||= @client.transactions(@client.selected_budget_id)
  end
end
