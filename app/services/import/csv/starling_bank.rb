require 'csv'

# @note This is used to import Starling Bank CSV Statements
# Export the statement CSV from within the app

class Import::Csv::StarlingBank
  def initialize(path, ynab_account_id = ENV['YNAB_STARLING_ACCOUNT_ID'])
    @path = path
    @ynab_account_id = ynab_account_id
    @import_id_creator = YNAB::ImportIdCreator.new
  end

  def import
    transactions_to_create = []

    ::CSV.foreach(@path, headers: true) do |transaction|
      # First row can be blank
      next unless transaction['Date'].present?

      amount = (transaction['Amount (GBP)'].to_f * 1000).to_i
      date = Date.parse(transaction['Date'])

      transactions_to_create << {
        id: @import_id_creator.import_id(amount, date),
        amount: amount,
        payee_name: transaction['Counter Party'],
        date: date,
        description: transaction['Reference']
      }
    end

    YNAB::BulkTransactionCreator.new(transactions_to_create, account_id: @ynab_account_id).create
  end
end
