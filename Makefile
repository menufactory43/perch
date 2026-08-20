.PHONY: test cli app generate

test:
	swift test

cli:
	swift build -c release --product perch

generate:
	xcodegen generate

app: generate
	xcodebuild -project Perch.xcodeproj -scheme Perch -configuration Debug -destination 'platform=macOS,arch=arm64' build
