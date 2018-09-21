class Import::Monzo
  BASE_URL = 'https://api.monzo.com'

  def initialize(access_token, monzo_account_id, ynab_account_id, from: 1.year.ago)
    @access_token = access_token
    @monzo_account_id = monzo_account_id
    @ynab_account_id = ynab_account_id
    @from = from
  end

  def import
    transactions_to_create = []
    transactions.reject { |t| t[:decline_reason].present? || t[:amount] == 0 }.each do |transaction|
      transactions_to_create << transaction_hash(transaction)
    end

    YNAB::BulkTransactionCreator.new(transactions_to_create, account_id: @ynab_account_id).create

    # Lets fixup any transactions if possible
    # @note this is very alpha, so i will keep it behind a feature flag for now
    if ENV['MONZO_FIXUP'].present?
      ynab_client = YNAB::Client.new(ENV['YNAB_ACCESS_TOKEN'], nil, @ynab_account_id)
      ynab_transactions = ynab_client.transactions(since_date: @from, account_id: @ynab_account_id)

      ynab_transactions_by_id = ynab_transactions.map{|t| [t.import_id, t] }.to_h
      monzo_transactions_by_id = transactions.reject { |t| t[:decline_reason].present? || t[:amount] == 0 }.map{|t| ["M#{t[:id]}", t] }.to_h

      ynab_transactions.each do |transaction|
        monzo_transaction = monzo_transactions_by_id[transaction.import_id]
        if monzo_transaction.present?

          up_to_date_transaction = transaction_hash(monzo_transaction)
          current_transaction = {
            id: transaction.import_id,
            amount: transaction.amount,
            payee_name: transaction.payee_name,
            date: transaction.date,
            description: transaction.memo,
            cleared: transaction.cleared.capitalize,
          }

          # If anything has changed, then lets update it.
          if (current_transaction.except(:cleared) != up_to_date_transaction.except(:flag, :cleared)) || (monzo_transaction[:settled].present? && transaction.cleared == 'uncleared')
            puts "#{transaction.import_id} NOT MATCH"
            ap ({ updated: up_to_date_transaction.except(:flag), current: current_transaction })
            puts 'Fixing...'

            ynab_client.update_transaction(transaction.id, up_to_date_transaction)

            puts 'done...'
            puts ''
          else
            puts "#{transaction.import_id} OK"
          end
        else
          puts "#{transaction.import_id} not found in Monzo"
          ap transaction
        end
      end

      monzo_transactions_by_id.each do |id, transaction|
        ynab_transaction = ynab_transactions_by_id["M#{transaction[:id]}"]

        if ynab_transaction.present?
          puts "M#{transaction[:id]} OK"
        else
          puts "#{"M#{transaction[:id]}"} NOT FOUND IN YNAB"
          ap transaction
        end
      end
    end
  end

  private

  def payee_name(transaction)
    payee_name = transaction[:merchant].try(:[], :name)
    payee_name ||= transaction[:counterparty][:name] if transaction[:counterparty].present?
    payee_name ||= 'Topup' if transaction[:is_load]
    payee_name ||= transaction[:description]
  end

  def description_and_flag(transaction)
    description = ''
    flag = nil

    foreign_transaction = transaction[:local_currency] != transaction[:currency]
    if foreign_transaction
      money = Money.new(transaction[:local_amount].abs, transaction[:local_currency])
      description.prepend("(#{money.format}) ")
      flag = 'orange' unless ENV['SKIP_FOREIGN_CURRENCY_FLAG'].present?
    end

    unless ENV['SKIP_EMOJI'].present?
      description.prepend("#{transaction[:merchant][:emoji]} ") if transaction[:merchant].try(:[], :emoji)
    end

    unless ENV['SKIP_TAGS'].present?
      description << transaction[:merchant][:metadata][:suggested_tags] if transaction[:merchant].try(:[], :metadata).try(:[], :suggested_tags)
    end

    [description.strip, flag]
  end

  def transaction_hash(transaction)
    description, flag = description_and_flag(transaction)

    {
      id: "M#{transaction[:id]}",
      amount: transaction[:amount] * 10,
      payee_name: payee_name(transaction),
      date: Time.parse(transaction[:created]).to_date,
      description: description,
      cleared: transaction[:settled].present? ? 'Cleared' : 'Uncleared',
      flag: flag
    }
  end

  def transactions
    since = @from.present? ? "&since=#{@from.strftime('%FT%TZ')}" : nil
    get("/transactions?account_id=#{@monzo_account_id}#{since}&expand[]=merchant")[:transactions]
  end

  def get(url)
    parse_response(RestClient.get(BASE_URL + url, { 'Authorization' => "Bearer #{@access_token}" }))
  end

  def parse_response(response)
    JSON.parse(response.body, symbolize_names: true)
  end
end
