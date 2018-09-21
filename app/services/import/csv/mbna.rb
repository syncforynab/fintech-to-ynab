require 'csv'

# @note This is used to import MBNA CSV Statements
# Export the statement CSV from within the web app

class Import::Csv::MBNA
  def initialize(path, ynab_account_id = ENV['YNAB_MBNA_ACCOUNT_ID'])
    @path = path
    @ynab_account_id = ynab_account_id
    @import_id_creator = YNAB::ImportIdCreator.new
  end

  def import
    transactions_to_create = []

    ::CSV.foreach(@path, headers: true) do |transaction|
      amount = (transaction['Amount'].to_f * 1000).to_i
      date = Date.parse(transaction['Transaction Date'])

      transactions_to_create << {
        id: @import_id_creator.import_id(amount, date),
        amount: amount,
        payee_name: transaction['Description'],
        date: date,
        description: transaction['Description']
      }
    end

    YNAB::BulkTransactionCreator.new(transactions_to_create, account_id: @ynab_account_id).create
  end
end
