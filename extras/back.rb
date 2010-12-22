# 背景画像をランダムに選んでリダイレクトする
get '/back_image' do
	#files = Dir.glob("public/back/*.jpg")
	#files = Dir::entries("public/back/")
	@files = []
	Dir::foreach('public/back/') do |f|
		next if f == "." or f == ".." or f == ".gitignore"
		@files.push f
	end
	send_file 'public/back/'+@files[rand(@files.size)]
end


# 背景画像一覧
get '/back' do
	@files = []
	Dir::foreach('public/back/') do |f|
		next if f == "." or f == ".." or f == ".gitignore"
		@files.push f
	end
	@files.map do |file|
		"<img src='/back/#{file}' width='300' height='240'>"
	end.join("\n")
end


