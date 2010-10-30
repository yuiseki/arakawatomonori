# Dropboxのフォルダを一覧する
get '/files' do
	@files = []
	Dir::foreach('public/file/') do |f|
		next if f == "." or f == ".." or f == ".gitignore" or f == "README.txt"
		@files.push f
	end
	@files.map do |file|
		"<a href='/file/#{file}'>#{file}</a>"
	end.join("<hr />\n")
end
