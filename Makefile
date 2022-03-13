git-hooker: main.nim
	nim c -d:release --opt:size -o:git-hooker main.nim
	strip git-hooker
