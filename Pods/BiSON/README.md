# README #
Library for converting to and from BSON

## Build library ##
```bash
./configure
make
```

## Install library ##
```bash
sudo make install
```

## Build Lua wrapper ##

### Install Dependencies ###
```bash
sudo apt-get install liblua5.2-dev
```

### Build Library ###
```bash
./configure --with-lua-wrapper=yes
make
```

### Using the Lua Library ###
```lua
bson = require("bson4lua");

bsonBytes = bson.to_bytes({
	doubleValue = {
		type = 0x01, --Double type
		value = 3.141592653589793
	},
	intValue = {
		type = 0x10, --Int32 Type
		value = 360
	},
	stringValue = {
		type = 0x02, --String type
		value = "A string of characters"
	}
});

print(bsonBytes:byte(1, string.len(bsonBytes)));

bsonTable = bson.to_table(string.char(0x05, 0x00, 0x00, 0x00, 0x00)); --Empty BSON document

print("Table: ");
for k, v in pairs(bsonTable) do
    print(k, v);
end
```

### Apple Platforms ###
There is a CocoaPod for iOS, MacOS, tvOS, and watchOS. Add to your podfile:

```ruby
pod 'BiSON'
```

### Android Platforms ###
There is a jCenter artifact for Android. Add the following to your `build.gradle`:

```
dependencies {
    compile ('com.smartdevicelink:bson_java_port:1.2.0')
}
```

## Build and run sample program ##
```bash
cd examples
gcc -o sample sample.c -lbson
./sample
```

## Build and run unit tests ##

Running unit tests requires `check` framework installed with pkg-config file (.pc). On Ubuntu, please install it by running:
```
sudo apt-get install check
```

Once the framework is installed, invoke `configure` with `--with-tests` option, build the library then run `make check`:

```bash
./configure --with-tests
make
make check
```
