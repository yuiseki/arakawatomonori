require 'sinatra/base'
require "google_spreadsheet"
require "fastercsv"
require "date"
require "rss/1.0"
require "rss/maker"
require "rss/dublincore"
# Google Spreadsheet 関係のヘルパー
module Sinatra
  module GdocsHelper
	# spreadsheetの内容を配列で返す
	def get_recents
		# キャッシュがあるか確認
		cache_path = options.settings["app"]["path"]+'tmp/gdocs.csv'
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
			ws = session.spreadsheet_by_key(options.settings["backend"]["sheet_key"]).worksheets[0]
			# frozenな配列なのでdupしてからいじる
			rows = ws.rows.dup
			# 先頭一行はヘッダなので削る
			rows.shift
			# 公表日時前のものは削除
			rows.delete_if{|row| Time.parse(row[0]) > Time.now }
			# 日時でソートする
			rows.sort {|a, b| Time.parse(b[0]) <=> Time.parse(a[0])}
			# pagerizeまでの暫定処理
			rows = rows[0...8]
			# キャッシュを残す
			FasterCSV.open(cache_path, "w") do |csv|
				rows.each do |row|
					csv << row
				end
			end
			return rows
		end
	end

	def expire_cache
		cache_path = options.settings["app"]["path"]+'tmp/gdocs.csv'
		if File.exist?(cache_path)
			File.delete(cache_path)
		end
	end

	# 公開日時に一致するエントリを得る
	def get_by_time(unixtime)
		cache_path = options.settings["app"]["path"]+'tmp/gdocs.csv'
		if File.exist?(cache_path)
			rows = FasterCSV.read(cache_path)
		else
			rows = get_recents
		end
		# マッチする行がなければnilが帰る
		row = rows.select{|r| Time.parse(row[0]) == unixtime}.first
	end

  # spreadsheetの配列をRSSに変換する
  def create_rss
	articles = get_recents
	rss = RSS::Maker.make("1.0") do |maker|
		maker.channel.about = options.settings["site"]["url"]+"rss"
		maker.channel.title = options.settings["site"]["title"]
		maker.channel.description = options.settings["site"]["desc"]
		maker.channel.link = options.settings["site"]["url"]
		maker.items.do_sort = false
		articles.each do |article|
			date = article[0]
			title = article[1]
			description = article[2]
			link = article[3]
			image = article[4]
			next if title.empty?
			
			item = maker.items.new_item
			item.link = (link.empty? ? maker.channel.link : link)
			item.title = title
			item.description = "<p>#{description}</p>" + "\r\n" +
				(image.empty? ? '' : "<img src='#{image}'>")
			begin
				item.date = Date.strptime(date, "%m/%d/%Y %H:%M:%S").to_s
			rescue
				item.date = Time.now
			end
		end
	end
	return rss.to_s
  end

  end

  helpers GdocsHelper
end
