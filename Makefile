.PHONY: format analyze run clean release

format:
	dart format lib

analyze:
	flutter analyze

run:
	flutter run

clean:
	flutter clean

release:
	flutter build apk --release