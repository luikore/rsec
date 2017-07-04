require "sinatra"
require "slim"

get '/' do
  slim :index
end

get '/ref' do
  slim :ref
end

get '/tricks' do
  slim :tricks
end

