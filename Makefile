VERSION=0.2.2

all: app

app: dic
	cd app && xcodebuild

install: app
	-killall Hiragany
	cp -R  app/build/Release/Hiragany.app ~/Library/Input\ Methods/
#	cp -R  app/build/Release/Hiragany.app /Library/Input\ Methods/

release: dist/Hiragany-${VERSION}.zip

dist/Hiragany-${VERSION}.zip: app/build/Release/Hiragany.app
	rm -rf dist/Hiragany-${VERSION}
	mkdir -p dist/Hiragany-${VERSION}
	cp README.txt dist/Hiragany-${VERSION}
	cp -R app/build/Release/Hiragany.app dist/Hiragany-${VERSION}
	cd dist && zip -r Hiragany-${VERSION}.zip Hiragany-${VERSION} 

dic: app/Resources/KanaKanji.plist

app/Resources/KanaKanji.plist: dict/*
	cd dict && ruby naist2plist.rb < naist-jdic-0.4.3.utf-8.dic > ../app/Resources/KanaKanji.plist

debug: dic
	cd app && xcodebuild -configuration Debug

debug-install:
	killall Hiragany
	cp -R  app/build/Debug/Hiragany.app /Library/Input\ Methods/
