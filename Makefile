VERSION=0.2

all:
	cd app && xcodebuild

install:
	killall Hiragany || cp -R  app/build/Release/Hiragany.app /Library/Input\ Methods/

release:
	rm -rf dist/Hiragany-${VERSION}
	mkdir -p dist/Hiragany-${VERSION}
	cp README.txt dist/Hiragany-${VERSION}
	cp -R app/build/Release/Hiragany.app dist/Hiragany-${VERSION}
	cd dist && zip -r Hiragany-${VERSION}.zip Hiragany-${VERSION} 

dic:
	cd dict && ruby mk_plist.rb hiragany.dict > ../app/Resources/KanaKanji.plist
