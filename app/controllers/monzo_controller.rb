class MonzoController < ApplicationController
  def receive
    ynab_creator = YNABTransactionCreator.new(
      params[:time],
      params[:amount],
      params[:payee],
      params[:description],
      cleared: true
    )

    render json: { saved: ynab_creator.create }
  end
end
