Rails.application.routes.draw do

  root to: 'application#home'
  get '/ping', to: 'application#ping'
  post '/monzo', to: 'monzo#receive'
  post '/starling', to: 'starling#receive'

end
