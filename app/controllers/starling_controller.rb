class StarlingController < ApplicationController
  def receive
    # @todo once starling support personal webhooks, add this support
    render json: { saved: false }
  end
end
