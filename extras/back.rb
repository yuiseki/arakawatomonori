# 背景画像をランダムに選んでリダイレクトする
get '/back.jpg' do
	files = Dir.glob("public/back/summer/*.jpg")
	send_file files[rand(files.size)]
end


# 背景画像一覧
get '/back' do
	@files = []
	Dir::foreach('public/back/summer/') do |f|
		next if f == "." or f == ".." or f == ".gitignore"
		@files.push f
	end
	@files.map do |file|
		"<img src='/back/summer/#{file}' width='300' height='240'>"
	end.join("\n")
end


