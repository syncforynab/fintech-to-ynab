class YNAB::TransactionCreator
  def initialize(date, amount, payee_name, description, cleared: true, budget_id: nil, account_id: nil)
    @date = date
    @amount = amount
    @payee_name = payee_name
    @description = description
    @cleared = cleared

    @client = YNAB::Client.new(ENV['YNAB_ACCESS_TOKEN'], budget_id, account_id)
  end

  def create
    payee_id = @client.lookup_payee_id(@payee_name)
    category_id = payee_id.present? ? lookup_category_id(payee_id) : nil

    return {error: :duplicate} if is_duplicate_transaction?(payee_id, category_id)

    # @note Until YNAB has the ability to create payees, lets pass the payee_name to the description for now.
    @description ||= ''
    @description << " (#{@payee_name})" if payee_id.nil?

    create = @client.create_transaction(
      budget_id: @client.selected_budget_id,
      account_id: @client.selected_account_id,
      payee_name: @payee_name,
      payee_id: payee_id,
      category_id: category_id,
      amount: @amount,
      cleared: @cleared,
      date: @date.to_date,
      memo: @description
    )

    create.try(:[], :transaction).present? ? create : { error: :failed }
  end

  private

  def is_duplicate_transaction?(payee_id, category_id)
    transactions.any? do |transaction|
      transaction[:date] == @date.to_date.to_s &&
        transaction[:amount] == @amount &&
        transaction[:payee_id] == payee_id &&
        transaction[:category_id] == category_id
    end
  end

  def lookup_category_id(payee_id)
    transactions.select{|a| a[:payee_id] == payee_id }.last.try(:[], :category_id)
  end

  def transactions
    @_transactions ||= @client.transactions(@client.selected_budget_id)
  end
end
