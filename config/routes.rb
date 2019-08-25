Rails.application.routes.draw do
  post '/callback' => 'linebot#callback'
  post '/callbackvn' => 'linebotvn#callbackvn'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
