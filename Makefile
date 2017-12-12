CFLAGS =

LDFLAGS =

build:
	swift build $(CFLAGS) $(LDFLAGS)

xcode:
	swift package $(CFLAGS) $(LDFLAGS) generate-xcodeproj --enable-code-coverage
	
test:
	swift build $(CFLAGS) $(LDFLAGS)
	swift test $(CFLAGS) $(LDFLAGS) 

clean:
	rm -rf Packages
	rm -rf .build
	rm -rf *.xcodeproj
	rm -rf Package.pins
	rm -rf Package.resolved
    