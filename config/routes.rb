Rails.application.routes.draw do
  root to: 'application#home'
  get '/ping', to: 'application#ping'
  post '/monzo', to: 'monzo#receive'
  post '/starling', to: 'starling#receive'
  post '/starling/feed-item', to: 'starlingv2#feed'
end