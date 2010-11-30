require 'oauth'
require 'twitter'
# twitter oauth
# gemsがバグっているので以下を参照して修復する必要あり
# http://d.hatena.ne.jp/hypercrab/20100704/1278182883
# oauth, twitter どちらも

require 'pstore'
require 'json/pure'
class JsonStore < PStore
  def initialize(file); super(file); end
  def dump(table); table.to_json; end
  def load(content); JSON.load(content); end
end


def base_url
	default_port = (request.scheme == "http") ? 80 : 443
	port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
	"#{request.scheme}://#{request.host}#{port}"
end

def oauth_consumer
	OAuth::Consumer.new(
					options.settings["oauth"]["key"],
					options.settings["oauth"]["secret"],
					:site => "http://twitter.com")
end

get '/twitter/auth' do
	@title = "荒川智則化装置"
	haml :twitter_auth
end

post '/twitter/auth' do
	# redirect to twitter oauth
	puts "starting oauth"
	puts options.settings["oauth"].inspect
	callback_url = "#{base_url}/twitter/return"
	puts callback_url
	begin
		request_token = oauth_consumer.get_request_token(:oauth_callback => callback_url)
	rescue OAuth::Unauthorized => @exception
		return erb %{ error: <%= @exception %> : <%= Time.now %> }
	end
	session[:request_token] = request_token.token
	session[:request_token_secret] = request_token.secret
	redirect request_token.authorize_url
end

get '/twitter/return' do
	puts "returned oauth"
  # return from twitter auth confirmed
  request_token = OAuth::RequestToken.new(
    oauth_consumer, session[:request_token], session[:request_token_secret])
  begin
    @access_token = request_token.get_access_token(
      {},
      :oauth_token => params[:oauth_token],
      :oauth_verifier => params[:oauth_verifier])
  rescue OAuth::Unauthorized => @exception
    return erb %{ error: <%= @exception %> }
  end

	twitter_oauth = Twitter::OAuth.new(
				options.settings["oauth"]["key"],
				options.settings["oauth"]["secret"]
	)
	twitter_oauth.authorize_from_access(@access_token.token, @access_token.secret)
	twitter = Twitter::Base.new(twitter_oauth)
	twitter.update_profile({:name=>"荒川智則"})

	screen_name = twitter.update_profile["screen_name"]
	# jsonstoreを利用してJSONに書きだす
	oauthdb = JsonStore.new(options.settings["app"]["path"]+'tmp/oauth.json')
	oauthdb.transaction do |oauthdb|
		oauthdb[screen_name] = Hash.new unless oauthdb[screen_name]
		oauthdb[screen_name]["updated_at"] = Time.now.to_i
		oauthdb[screen_name]["created_at"] = Time.now.to_i unless oauthdb[screen_name]["created_at"]
		oauthdb[screen_name]["access"] = {"token" => @access_token.token, "secret" => @access_token.secret}
		puts "oauth log #{screen_name} #{oauthdb[screen_name].inspect}"
	end

	#redirect "http://twitter.com/"+screen_name
	redirect "http://twitter.com/?status=%E8%8D%92%E5%B7%9D%E6%99%BA%E5%89%87%E3%81%AB%E3%81%AA%E3%82%8A%E3%81%BE%E3%81%97%E3%81%9F%20http://bit.ly/bjk6o1%20%23arakawa12"
end

