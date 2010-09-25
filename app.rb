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
      #puts options.account["username"]
      #puts  options.account["password"]
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
end

# 公開フォルダ一覧
get '/files' do
  @files = []
  Dir::foreach('public/file/') {|f|
    next if f == "." or f == ".." or f == ".gitignore" or f == "README.txt"
    @files.push f
  }
  @files.map{|file| "<a href='/file/#{file}'>#{file}</a>"}.join("<hr />\n")
end

# 背景画像一覧
get '/back' do
  @files = []
  Dir::foreach('public/back/summer/') {|f|
    next if f == "." or f == ".." or f == ".gitignore"
    @files.push f
  }
  @files.map{|file| "<img src='/back/summer/#{file}' width='300' height='240'>"}.join("\n")
end


# 背景画像をランダムに選んでリダイレクトする
get '/back.jpg' do
  files = Dir.glob("public/back/summer/*.jpg")
  send_file files[rand(files.size)]
end


# <a href="http://twitter.com/share" class="twitter-share-button" data-url="http://荒川智則.jp/" data-count="vertical">Tweet</a>
# <script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>

template :index do
<<EOF
!!!
%html
  %head
    %meta{ 'http-equiv' => 'content', :content => 'text/html; charset=utf-8'}
    %meta{ 'name' => 'google-site-verification', :content => 'RqlA5emwjXQDEkZISWWiHkyFSNorrFiiaGrUKPlGnQw'}
    %title=@title
  %body{:style=>"background-image: url(/back.jpg); font-family:san-selif; background-size: contain;"}
    %div{:style=>"width:650px;margin:auto;"}
      %a{:href=>"http://twitter.com/share", :class=>"twitter-share-button", :"data-url"=>"http://荒川智則.jp/"}
        Tweet
      %script{:src=>"http://platform.twitter.com/widgets.js", :type=>"text/javascript"}
      %h1{:style=>"margin:50px; padding:10px; font-size:5em; background-image: url(/white80.png); border:1px solid black; border-radius:10px; -webkit-border-radius: 10px; -moz-border-radius:10px;"}=@title
      - @result.each do |i|
        - unless i[1] == ""
          %div{:style=>"background-image: url(/white80.png); margin:50px; padding:15px; border:1px solid black; border-radius:10px; -webkit-border-radius: 10px; -moz-border-radius:10px;"}
            %a{:href=>i[3], :style=>"text-decoration: none;"}
              %h2= i[1]
              %p{:style=>"color:black;"}= i[0]
              %pre{:style=>"color:black;"}= i[2]
              - unless i[4] == ""
                %img{:src=>i[4], :style=>"max-height:500px; max-width:500px;"}
EOF
end



