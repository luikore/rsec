require "sinatra"
require "sinatra/reloader" if development?
require "slim"

module Sinatra
  module Templates
    def slim template, opts={}, locals={}
      render :slim, template, opts, locals
    end
  end
end

get '/' do
  slim :index
end

get '/doc' do
  slim :doc
end

get '/tricks' do
  slim :tricks
end

