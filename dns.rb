require 'rubygems'
require 'sinatra'
require 'escape'
require 'erb'

IP_REGEXP = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/

class BadInputError < StandardError; end

helpers do
  def clean_hostname(hn)
    hn = hn.strip.sub(/[><|&;\s].*/, '')
    raise BadInputError if hn.length == 0
    hn
  end
end

before do
  headers 'Cache-Control' => 'public, max-age=60'
  @hostname = nil
  @output = nil
end

get '/' do
  headers 'Cache-Control' => 'public, max-age=900'
  erb :index
end

['/dig/:type/:hostname', '/dig/:hostname'].each do |path|
  get path do
    type = %w[a mx ns any txt srv aaaa].include?(params[:type]) ? params[:type] : 'a'
    @hostname = clean_hostname(params[:hostname])
    @output = "<strong>$ dig #{type} #{@hostname}</strong>\n" +
              `#{Escape.shell_command(["dig", type, @hostname])}`.strip
    erb :index
  end
end

get '/reverse/:hostname' do
  raise BadInputError unless params[:hostname] =~ IP_REGEXP
  @hostname = params[:hostname]
  @output = "<strong>$ dig -x #{@hostname}</strong>\n" +
            `#{Escape.shell_command(["dig", "-x", @hostname])}`.strip
  erb :index
end

get '/lookup/:hostname' do
  @hostname = clean_hostname(params[:hostname])
  @output = "<strong>$ nslookup #{@hostname}</strong>\n" +
            `#{Escape.shell_command(["nslookup", @hostname])}`.strip
  erb :index
end

get '/whois/:hostname' do
  @hostname = clean_hostname(params[:hostname])
  @output = "<strong>$ whois #{params[:hostname]}</strong>\n" +
            `#{Escape.shell_command(["whois", @hostname])}`.strip
  erb :index
end

get '/:hostname' do
  redirect "/dig/#{params[:hostname]}"
end

not_found do
  redirect '/'
end

error BadInputError do
  redirect '/'
end