# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'haml'
require "google_spreadsheet"
require "pit"
require "fastercsv"

configure do
	set :account, Pit.get("google.com", :require => {
									 "username" => "your email in Google",
									 "password" => "your password in Google",
								 })
end

helpers do
	def get_gdocs
		# キャッシュがあるか確認
		cache_path = 'tmp/gdocs.csv'
		if File.exist?(cache_path)
			# csvからrowsをかえす
			rows = FasterCSV.read(cache_path)
			# 期限が切れていたら削除
			cache_elapse = Time.now - File::mtime(cache_path)
			File.delete(cache_path) if cache_elapse > 3200
			return rows
		else
			puts "gdocs api access"
			# タイムアウトしてたらAPI叩く
			session = GoogleSpreadsheet.login(options.account["username"], options.account["password"])
			ws = session.spreadsheet_by_key("tZ034W7OBe2_nmdh5XVw8Tg").worksheets[0]
			# frozenな配列なのでdupしてからいじる
			rows = ws.rows.dup
			# 先頭一行はヘッダなので削る
			rows.shift
			# 公表日時前のものは削除
			rows.delete_if{|row| Time.parse(row[0]) > Time.now }
			# キャッシュを残す
			FasterCSV.open(cache_path, "w") do |csv|
				rows.each do |row|
					csv << row
				end
			end
			return rows
		end
	end
end

get '/' do
	@title = "荒川智則.jp"
	@result = get_gdocs
	haml :index
end

get '/rss' do
	articles = get_gdocs
	rss = RSS::Maker.make("1.0", ["dublincore"]) do |maker|
		maker.channel.about = "http://xn--fdr45z90g374a.jp/rss"
		maker.channel.title = "荒川智則.jp"
		maker.channel.description = "東京の中央線に住んでいる無職と言われて思い浮かぶイメージのまんまの男。つまり、リベラルでポストモダンでオルタナティブでサブカルでロックなグランジでカート・コバーンを尊敬していて２７才で死ぬ定めにあると思っている。"
		maker.channel.link = "http://xn--fdr45z90g374a.jp/"

		maker.items.do_sort = true

		articles.each do |article|
			date = i[0]
			title = article[1]
			description = article[2]
			link = article[3]
			image = article[4]

			next unless title
			
			item = maker.items.new_item
			item.link = link if link
			item.title = title
			item.description = "<p>#{description}</p>" + "\r\n" +
				image ? "<img src='#{image}'>" : ''
			item.date = Date.parse(date)
		end
	end
	rss.to_s
end

# 背景画像をランダムに選んでリダイレクトする
get '/back.jpg' do
	files = Dir.glob("public/back/summer/*.jpg")
	send_file files[rand(files.size)]
end

#-o-background-size:100% 100%, auto; -moz-background-size:100% 100%, auto; -webkit-background-size:100% 100%, auto; background-size: 100% 100%, auto; 
template :index do
	<<EOF
!!!
%html
  %head
    %meta{ 'http-equiv' => 'content', :content => 'text/html; charset=utf-8'}
    %title=@title
  %body{:style=>"background-image: url(/back.jpg); font-family:san-selif; background-size: contain;"}
    %div{:style=>"width:800px;margin:auto;"}
      %h1{:style=>"margin:15px; padding:10px; font-size:5em; background-image: url(/white80.png); border:1px solid black; border-radius:10px; -webkit-border-radius: 10px; -moz-border-radius:10px;"}=@title
      - @result.each do |i|
        - unless i[1] == ""
          %div{:style=>"background-image: url(/white80.png); margin:15px; padding:15px; border:1px solid black; border-radius:10px; -webkit-border-radius: 10px; -moz-border-radius:10px;"}
            %a{:href=>i[3], :style=>"text-decoration: none;"}
              %h2= i[1]
              %p{:style=>"color:black;"}= i[0]
              %pre{:style=>"color:black;"}= i[2]
              - unless i[4] == ""
                %img{:src=>i[4], :style=>"max-height:500px; max-width:500px;"}
EOF
end



