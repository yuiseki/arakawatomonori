# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'haml'
require "pit"

require "helpers/gdocs"

configure do
	#require 'openssl'
	#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
	use Rack::Session::Cookie, :secret => Digest::SHA1.hexdigest(rand.to_s)
	set :settings, YAML.load_file("settings.yaml")
	set :account, Pit.get("google.com", :require => {
							 "username" => "your email in Google",
							 "password" => "your password in Google",
				 })
end

def sitemap(path, desc)
end

get'/', {'sitemap' => ['/', 'サイトのトップページです']} do
	@title = options.settings["site"]["title"]
	@desc = "サイトのトップページです"
	@result = get_recents
	haml :root
end

get '/style.css' do
	content_type 'text/css', :charset => 'utf-8'
	sass :style
end

get '/rss' do
	create_rss
end

get '/expire' do
	expire_cache
	redirect '/'
end

get '/entry/:time' do
	@content = get_by_time(params[:time])
	haml :entry
end

get 'page/' do
end

load "extras/oauth.rb"

# ランダム背景画像
load "extras/back.rb"
# Dropbox共有フォルダ公開
load "extras/file.rb"

