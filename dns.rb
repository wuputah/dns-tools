require 'rubygems'
require 'sinatra'
require 'escape'
require 'erb'

IP_REGEXP = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/

class BadInputError < StandardError; end

helpers do
  def clean_hostname(hn)
    hn.strip.sub(/\s.*/, '')
  end
end

before do
  headers 'Cache-Control' => 'public, max-age=60'
end

get '/' do
  erb :index
end

get '/dig/:type/:hostname' do
  type = %w[a mx ns any txt srv aaaa].include?(params[:type]) ? params[:type] : 'a'
  hostname = clean_hostname(params[:hostname])
  raise BadInputError if hostname.length == 0
  @output = "<strong>$ dig #{type} #{hostname}</strong>\n" +
            `#{Escape.shell_command(["dig", type, hostname])}`.strip
  erb :index
end

get '/dig/:hostname' do
  redirect "/dig/a/#{params[:hostname]}"
end

get '/reverse/:hostname' do
  raise BadInputError unless params[:hostname] =~ IP_REGEXP
  @output = "<strong>$ dig -x #{params[:hostname]}</strong>\n" +
            `#{Escape.shell_command(["dig", "-x", params[:hostname]])}`.strip
  erb :index
end

get '/lookup/:hostname' do
  hostname = clean_hostname(params[:hostname])
  raise BadInputError if hostname.length == 0
  @output = "<strong>$ nslookup #{params[:hostname]}</strong>\n" +
            `#{Escape.shell_command(["nslookup", params[:hostname]])}`.strip
  erb :index
end

get '/whois/:hostname' do
  hostname = clean_hostname(params[:hostname])
  raise BadInputError if hostname.length == 0
  @output = "<strong>$ whois #{params[:hostname]}</strong>\n" +
            `#{Escape.shell_command(["whois", params[:hostname]])}`.strip
  erb :index
end

not_found do
  redirect '/'
end

error BadInputError do
  redirect '/'
end