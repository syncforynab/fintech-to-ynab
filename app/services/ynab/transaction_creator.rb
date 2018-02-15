class YNAB::TransactionCreator
  def initialize(id: nil, date: nil, amount: nil, payee_name: nil, description: true, flag: nil, cleared: true, budget_id: nil, account_id: nil)
    @id = id
    @date = date
    @amount = amount
    @payee_name = payee_name
    @description = description
    @cleared = cleared
    @flag = flag

    @client = YNAB::Client.new(ENV['YNAB_ACCESS_TOKEN'], budget_id, account_id)
  end

  def create
    begin
      create = @client.create_transaction(
        id: @id,
        payee_name: @payee_name,
        amount: @amount,
        cleared: @cleared,
        date: @date.to_date,
        memo: @description,
        flag: @flag
      )
    rescue => e
      return JSON.parse(e.response.body, symbolize_names: true)
    end

    create.try(:[], :transaction).present? ? create : { error: :failed, data: create }
  end
end
