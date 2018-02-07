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

    return { error: :duplicate } if is_duplicate_transaction?(payee_id, category_id, @date.to_date, @amount)

    create = @client.create_transaction(
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
end
