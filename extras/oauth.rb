require 'oauth'
require 'twitter'
# twitter oauth
# gemsがバグっているので以下を参照して修復する必要あり
# http://d.hatena.ne.jp/hypercrab/20100704/1278182883
# oauth, twitter どちらも
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
  session[:access_token] = @access_token.token
  session[:access_token_secret] = @access_token.secret

	twitter_oauth = Twitter::OAuth.new(
				options.settings["oauth"]["key"],
				options.settings["oauth"]["secret"]
	)
	twitter_oauth.authorize_from_access(session[:access_token], session[:access_token_secret])
	twitter = Twitter::Base.new(twitter_oauth)
	twitter.update_profile({:name=>"荒川智則"})
	screen_name = twitter.update_profile["screen_name"]
	log = {:screen_name => screen_name,
		 :access_token => session[:access_token],
		 :access_token_secret => session[:access_token_secret],
		 :twitter_oauth => true}
	puts log.inspect
	redirect "http://twitter.com/"+screen_name
end

