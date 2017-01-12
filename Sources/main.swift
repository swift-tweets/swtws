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
    case resolveImage = "--resolve-image"
    case resolveCode = "--resolve-code"
    case presentation = "--presentation"
    case c = "-c"
    case count = "--count"
    case length = "--length"
    case twitter = "--twitter"
    case qiita = "--qiita"
    case github = "--github"
}

enum Option {
    case help
    case resolveImage
    case resolveCode
    case presentation
    case count
    case length
    case twitter(credential: OAuthCredential)
    case qiita(token: String)
    case github(token: String)
}

extension Option: Equatable {
    static func ==(lhs: Option, rhs: Option) -> Bool {
        switch (lhs, rhs) {
        case (.help, .help):
            return true
        case (.resolveImage, .resolveImage):
            return true
        case (.resolveCode, .resolveCode):
            return true
        case (.presentation, .presentation):
            return true
        case (.count, .count):
            return true
        case (.length, .length):
            return true
        case let (.twitter(credential1), .twitter(credential2)):
            return credential1 == credential2
        case let (.github(token1), .github(token2)):
            return token1 == token2
        case let (.qiita(token1), .qiita(token2)):
            return token1 == token2
        case (_, _):
            return false
        }
    }
}

enum ParseError: Error {
    case lackOfArgument(OptionName)
    case illegalOption(String)
    case illegalArgumentFormat(OptionName, String)
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
            case .resolveImage:
                options.append(.resolveImage)
            case .resolveCode:
                options.append(.resolveCode)
            case .presentation:
                options.append(.presentation)
            case .c, .count:
                options.append(.count)
            case .length:
                options.append(.length)
            case .twitter:
                guard let argument = iterator.next() else {
                    throw ParseError.lackOfArgument(optionName)
                }
                let arguments = argument.components(separatedBy: ",")
                guard arguments.count == 4 else {
                    throw ParseError.illegalArgumentFormat(optionName, argument)
                }

                let consumerKey = arguments[0]
                let consumerSecret = arguments[1]
                let oauthToken = arguments[2]
                let oauthTokenSecret = arguments[3]
                    
                options.append(.twitter(credential: OAuthCredential(
                    consumerKey: consumerKey,
                    consumerSecret: consumerSecret,
                    oauthToken: oauthToken,
                    oauthTokenSecret: oauthTokenSecret
                )))
            case .qiita:
                guard let argument = iterator.next() else {
                    throw ParseError.lackOfArgument(optionName)
                }
                options.append(.qiita(token: argument))
            case .github:
                guard let argument = iterator.next() else {
                    throw ParseError.lackOfArgument(optionName)
                }
                options.append(.github(token: argument))
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
    case lackOfGithubToken
}

func command(inputs: [String], options: [Option]) throws {
    if let option = options.first {
        switch option {
        case .help:
            printHelp { print($0) }
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
    
    var tweets = try Tweet.tweets(from: string, hashTag: "#swtws")
    
    if options.contains(.count) {
        printCount(of: tweets)
    } else {
        let speaker = createSpeaker(with: options)
        if options.contains(.resolveCode) {
            tweets = try sync(operation: speaker.resolveCodes)(tweets)
        }
        if options.contains(.resolveImage) {
            tweets = try sync(operation: speaker.resolveImages)(tweets)
        }
        
        let displaysLengths = options.contains(.length)
        
        print(tweets.map {
            if displaysLengths {
                return "[\($0.length)]\n\n" + $0.description
            } else {
                return $0.description
            }
        }.joined(separator: "\n\n---\n\n"))
    }
}

func printHelp(_ print: (String) -> ()) {
    print("OVERVIEW: Command line tool for Swift Tweets")
    print("")
    print("USAGE: swtws [-h | --help]")
    print("             [[-c | --count] [--length] <input>]")
    print("             [--resolve-image --twitter <oauth-credential> <input>]")
    print("                 <oauth-credential> = <consumer-key>,<consumer-secret>,<oauth-token>,<oauth-token-secret>")
    print("             [--resolve-code --github <access-token> <input>]")
    print("")
    print("OPTIONS:")
    print("  -c, --count            Display counts of tweets")
    print("  -h, --help             Display this document")
    print("  --length               Display the lengths of tweets")
    print("  -resolve-code          Upload codes to Gist and replace them with links and Gist IDs")
    print("  -resolve-image         Upload images to Twitter and replace them with media IDs")
}

func printCount(of tweets: [Tweet]) {
    print(tweets.count)
}

func createSpeaker(with options: [Option]) -> Speaker {
    let twitterCredential: OAuthCredential? = options.flatMap { option in
        guard case let .twitter(credential) = option else {
            return nil
        }
        return credential
        }.last
    let githubToken: String? = options.flatMap { option in
        guard case let .github(token) = option else {
            return nil
        }
        return token
        }.last
    
    return Speaker(twitterCredential: twitterCredential, githubToken: githubToken)
}

func main(_ arguments: [String]) {
    do {
        let (inputs, options) = try parse(arguments.tail)
        try command(inputs: inputs, options: options)
    } catch let error {
        fputs("ERROR: \(error)\n", stderr)
        fputs("\n", stderr)
        fputs("================================================================\n", stderr)
        fputs("\n", stderr)
        printHelp { fputs("\($0)\n", stderr) }
    }
}

main(CommandLine.arguments)
