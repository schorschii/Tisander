# JSONSwift

[![Build Status](https://travis-ci.org/mikezs/Tisander.svg?branch=master)](https://travis-ci.org/mikezs/Tisander)

## Ordered JSON parser in pure swift

I needed a JSON parser that has all of the items in dictionaries to be sorted to work around an issue where an existing API couldn't be changed to return objects in an array. In my quest to find this, I noticed almost all parsers used `JSONSerialization` from Apple to create their dictionaries and the dictionaries (quite correctly) has no order, but it was not consistent. Different platforms (simulator vs device) would give different orders and this is not something I could accept in my work.

The parser is now pure Swift and returns an array of either `JSON.ArrayValues` or `JSON.ObjectValues` (depending on what the structure was when they were parsed). This can be accessed by subscripting a `String` or `Int` and then cast to get values. Most importantly for me, you can get .allKeys from the array of `JSON.ObjectValues` and they are sorted in the order they were in the JSON file because JSONSwift is: A JSON parser written from the ground up in pure Swift. It is a functional recursive descent parser.

### Installing

#### Cocoapods

Add this to your Podfile

```
pod 'Tisander', '~> 1.0'
```

#### Manual

Copy "JSON.swift" file into your project. Or just import the framework. That's it. :)

### How to use:

#### Parse JSON Object

```json
// Data

{
    "MONDAY": [
        {
            "TITLE":   "TEST DRIVEN DEVELOPMENT",
            "SPEAKER": "JASON SHAPIRO",
            "TIME": "9:00 AM"
        },
        {
            "TITLE": "JAVA TOOLS",
            "SPEAKER": "JIM WHITE",
            "TIME": "9:00 AM"
        }
    ],
    "TUESDAY": [
        {
            "TITLE": "MONGODB",
            "SPEAKER": "DAVINMICKELSON",
            "TIME": "1: 00PM"
        },
        {
            "TITLE": "DEBUGGINGWITHXCODE",
            "SPEAKER": "JASONSHAPIRO",
            "TIME": "1: 00PM",
        }
    ]
}
```

Call the static method `JSON.parse(data:)` with the jsonData string, and use optional chaining to get the values you want:

```
JSON.parse(data: jsonData)?["MONDAY"]?.values?.forEach({ (day) in
        print(day["TITLE"])
    })
```

### Authors

Tisander author:

[Mike Bignell](https://github.com/mikezs)

JSONSwift authors:

[Ankit Goel](https://github.com/ankit1ank)

[Kartik Yelchuru](https://github.com/buildAI)
