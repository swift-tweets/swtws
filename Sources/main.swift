import Foundation
import TweetupKit

extension Array {
    var tail: ArraySlice<Element> {
        return self[1..<endIndex]
    }
}

enum OptionName: String {
    case h = "-h"
    case help = "--help"
    case c = "-c"
    case count = "--count"
    case twitter = "--twitter"
    case qiita = "--qiita"
    case github = "--github"
    case presentation = "--post"
}

enum Option {
    case help
    case count
    case twitter(path: String)
    case qiita(path: String)
    case github(path: String)
    case post
}

enum ParseError: Error {
    case lackOfArgument(OptionName)
    case illegalOption(String)
}

func parse<S: Sequence>(_ arguments: S) throws -> ([String], [Option]) where S.Iterator.Element == String {
    var inputs = [String]()
    var options = [Option]()
    
    var iterator = arguments.makeIterator()
    while true {
        guard let argument = iterator.next() else {
            break
        }
        switch OptionName(rawValue: argument) {
        case .none:
            if argument.hasPrefix("-") {
                throw ParseError.illegalOption(argument)
            }
            inputs.append(argument)
        case let .some(optionName):
            switch optionName {
            case .h, .help:
                options.append(.help)
            case .c, .count:
                options.append(.count)
            case .presentation:
                options.append(.post)
            case .twitter:
                guard let argument = iterator.next() else {
                    throw ParseError.lackOfArgument(optionName)
                }
                options.append(.twitter(path: argument))
            case .qiita:
                guard let argument = iterator.next() else {
                    throw ParseError.lackOfArgument(optionName)
                }
                options.append(.qiita(path: argument))
            case .github:
                guard let argument = iterator.next() else {
                    throw ParseError.lackOfArgument(optionName)
                }
                options.append(.github(path: argument))
            }
        }
    }
    
    return (inputs, options)
}

enum CommandError: Error {
    case noInput
    case multipleInputs([String])
    case noSuchFile(path: String)
    case illegalEncoding(path: String)
}

func command(inputs: [String], options: [Option]) throws {
    if let option = options.first {
        switch option {
        case .help:
            printHelp()
            return
        default:
            break
        }
    }
    
    guard inputs.count <= 1 else { throw CommandError.multipleInputs(inputs) }
    guard let input = inputs.first else { throw CommandError.noInput }
    
    guard let data = FileManager.default.contents(atPath: input) else {
        throw CommandError.noSuchFile(path: input)
    }
    guard let string = String(data: data, encoding: .utf8) else {
        throw CommandError.illegalEncoding(path: input)
    }
    
    let tweets = try Tweet.tweets(from: string, hashTag: "#swtws")

    if options.contains(where: {
        switch $0 {
        case .count:
            return true
        default:
            return false
        }
    }) {
        printCount(of: tweets)
    } else {
        print(tweets.map { "[\($0.length)]\n\n" + $0.description }.joined(separator: "\n\n---\n\n"))
    }
}

func printHelp() {
    print("OVERVIEW: Command line tool for Swift Tweets")
    print()
    print("USAGE: swtws [-h | --help]")
    print("             [[-c | --count] <input>]")
    print()
    print("OPTIONS:")
    print("  -c, --count            Display counts of tweets")
    print("  -h, --help             Display this document")
}

func printCount(of tweets: [Tweet]) {
    print(tweets.count)
}

func main(_ arguments: [String]) {
    do {
        let (inputs, options) = try parse(arguments.tail)
        try command(inputs: inputs, options: options)
    } catch let error {
        print(error)
        print()
        printHelp()
    }
}

main(CommandLine.arguments)
