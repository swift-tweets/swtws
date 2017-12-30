import Foundation
import Commander
import TweetupKit
import PromiseK

extension Promise {
    func sync() -> Value {
        var resultValue: Value!
        var waiting = true
        get { value in
            resultValue = value
            waiting = false
        }
        let runLoop = RunLoop.current
        while waiting && runLoop.run(mode: .defaultRunLoopMode, before: .distantFuture) { }
        return resultValue
    }
}

extension APIError : CustomStringConvertible {
    public var description: String {
        return "[APIError] response = \(response), json = \(json)"
    }
}

extension CodeRendererError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .illegalResponse:
            return "[CodeRendererError] Illegal response during code rendering."
        case .writingFailed:
            return "[CodeRendererError] Failed to write images of code."
        }
    }
}

extension TweetParseError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .codeWithoutFileName(let code):
            return "[TweetParseError] TweetParseError: Code without filename: \(code)"
        case .illegalHashTag(let hashtag):
            return "[TweetParseError] Illegal hashtag: \(hashtag)"
        case .multipleAttachments(let tweet, let attachments):
            return "[TweetParseError] Multiple attachments in a tweet: tweet = \(tweet), attachments = \(attachments)"
        case .nonTailAttachment(let tweet, let attachment):
            return "[TweetParseError] Attachment must be put at the end of a tweet: tweet = \(tweet), attachment = \(attachment)"
        }
    }
}

extension SpeakerError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .noGithubToken:
            return "[SpeakerError] Lack of GitHub token."
        case .noOutputDirectoryPath:
            return "[SpeakerError] Lack of image output directory path."
        case .noTwitterCredential:
            return "[SpeakerError] Lack of Twitter credential."
        }
    }
}

extension TweetInitializationError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "[TweetInitializationError] Empty tweet."
        case .tooLong(let tweet, let attachment, let length):
            return "[TweetInitializationError] Too long tweet: tweet = \(tweet), attachment = \(String(describing: attachment)), length = \(length)"
        }
    }
}

enum CommandError : Error {
    case noInput
    case multipleInputs([String])
    case noSuchFile(path: String)
    case illegalEncoding(path: String)
    case lackOfGithubToken
    case illegalTwitterCredentialFormat(String)
}

func decodedTweets(from file: String) throws -> [Tweet] {
    guard let data = FileManager.default.contents(atPath: file) else {
        throw CommandError.noSuchFile(path: file)
    }
    guard let string = String(data: data, encoding: .utf8) else {
        throw CommandError.illegalEncoding(path: file)
    }
    return try Tweet.tweets(from: string, hashTag: "#swtws")
}

func parsedTwitterCredential(from twitterCredentialString: String) throws -> OAuthCredential {
    let arguments = twitterCredentialString.components(separatedBy: ",")
    guard arguments.count == 4 else {
        throw CommandError.illegalTwitterCredentialFormat(twitterCredentialString)
    }
    
    let consumerKey = arguments[0]
    let consumerSecret = arguments[1]
    let oauthToken = arguments[2]
    let oauthTokenSecret = arguments[3]
    
    return OAuthCredential(
        consumerKey: consumerKey,
        consumerSecret: consumerSecret,
        oauthToken: oauthToken,
        oauthTokenSecret: oauthTokenSecret
    )
}

func printTweets(_ tweets: [Tweet], displaysLengths: Bool = false) {
    print(tweets.map {
        if displaysLengths {
            return "[\($0.length)]\n\n" + $0.description
        } else {
            return $0.description
        }
    }.joined(separator: "\n\n---\n\n"))
}

func printCount(of tweets: [Tweet]) {
    print(tweets.count)
}

let main = Group {
    $0.addCommand("resolve-code", """
        Post code in the given tweets to Gist, and output tweets in which the code are replated with links to the gists and their IDs.

                swtws resolve-code [--github token] <tweets-file-path>

                    --github  Access token to post code to Gist.

        """, command(
            Option("github", default: ""),
            Argument<String>("tweets-file-path")
        ) { (githubToken: String, tweetsFilePath: String) in
            let baseDirectoryPath = (tweetsFilePath as NSString).deletingLastPathComponent
            let speaker = Speaker(
                twitterCredential: nil,
                githubToken: githubToken.isEmpty ? nil : githubToken,
                baseDirectoryPath: baseDirectoryPath,
                outputDirectoryPath: nil
            )
            let tweets = try decodedTweets(from: tweetsFilePath)
            let outputTweets = try speaker.resolveCodes(of: tweets).sync()()
            printTweets(outputTweets)
        })
    $0.addCommand("resolve-gist", """
        Capture images of code represented as Gist IDs in given tweets, write them into the specified directory, and output tweets in which the Gist IDs are replaced with image paths.

                swtws resolve-gist [--image-output path] <tweets-file-path>

                    --image-output  Directory path in which images of code are written.

        """, command(
            Option("image-output", default: ""),
            Argument<String>("tweets-file-path")
        ) { (imagesOutputDirectoryPath: String, tweetsFilePath: String) in
            let baseDirectoryPath = (tweetsFilePath as NSString).deletingLastPathComponent
            let speaker = Speaker(
                twitterCredential: nil,
                githubToken: nil,
                baseDirectoryPath: baseDirectoryPath,
                outputDirectoryPath: imagesOutputDirectoryPath.isEmpty ? nil : imagesOutputDirectoryPath
            )
            let tweets = try decodedTweets(from: tweetsFilePath)
            let outputTweets = try speaker.resolveGists(of: tweets).sync()()
            printTweets(outputTweets)
        })
    $0.addCommand("resolve-image", """
        Upload images in the given tweets to Twitter, and output tweets in which the images are replaced with media IDs.

                swtws resolve-image [--twitter credential] <tweets-file-path>

                    --twitter  Credentials to post tweets to Twitter, whose format is <consumer-key>,<consumer-secret>,<oauth-token>,<oauth-token-secret>.

        """, command(
            Option("twitter", default: ""),
            Argument<String>("tweets-file-path")
        ) { (twitterCredentialString: String, tweetsFilePath: String) in
            let baseDirectoryPath = (tweetsFilePath as NSString).deletingLastPathComponent
            let twitterCredential = twitterCredentialString.isEmpty ? nil : try parsedTwitterCredential(from: twitterCredentialString)
            let speaker = Speaker(twitterCredential: twitterCredential, githubToken: nil, baseDirectoryPath: baseDirectoryPath, outputDirectoryPath: nil)
            let tweets = try decodedTweets(from: tweetsFilePath)
            let outputTweets = try speaker.resolveImages(of: tweets).sync()()
            printTweets(outputTweets)
        })
    $0.addCommand("presentation", """
        Make a presentation by posting the given tweets.

                swtws presentation [--interval interval] [--github token] [--image-output path] [--twitter credential] <tweets-file-path>

                    --interval      Intarvals of tweets in seconds.
                    --github        Access token to post code to Gist.
                    --image-output  Directory path in which images of code are written. This path is relative from the tweets files.
                    --twitter       Credentials to post tweets to Twitter, whose format is <consumer-key>,<consumer-secret>,<oauth-token>,<oauth-token-secret>.

        """, command(
            Option("interval", default: 30.0),
            Option("github", default: ""),
            Option("image-output", default: ""),
            Option("twitter", default: ""),
            Argument<String>("tweets-file-path")
        ) { interval, githubToken, imagesOutputDirectoryPath, twitterCredentialString, tweetsFilePath in
            let baseDirectoryPath = (tweetsFilePath as NSString).deletingLastPathComponent
            let twitterCredential = twitterCredentialString.isEmpty ? nil : try parsedTwitterCredential(from: twitterCredentialString)
            let speaker = Speaker(
                twitterCredential: twitterCredential,
                githubToken: githubToken.isEmpty ? nil : githubToken,
                baseDirectoryPath: baseDirectoryPath,
                outputDirectoryPath: imagesOutputDirectoryPath.isEmpty ? nil : imagesOutputDirectoryPath
            )
            let tweets = try decodedTweets(from: tweetsFilePath)
            let responses = try speaker.post(tweets: tweets, interval: interval).sync()()
            assert(tweets.count == responses.count)
            let tweetQuotations: [String] = zip(tweets, responses).map { tweet, response in
                """
                @\(response.screenName) \(response.statusId)
                \(tweet.description)
                """
            }
            print(tweetQuotations.joined(separator: "\n\n"))
        })
    $0.addCommand("check", """
        Check the format of the given tweets by parsing them, and display the tweets with inserted hashtags.

                swtws [-c|--count] [--length] <tweets-file-path>

                    -c, --count  Display the count of the given tweets.
                    --length     Display the length of the given tweets additionally.

        """, command(
            Flag("count", flag: "c"),
            Flag("length"),
            Argument<String>("tweets-file-path")
        ) { countFlag, lengthFlag, tweetsFilePath in
            let tweets = try decodedTweets(from: tweetsFilePath)
            
            if countFlag {
                printCount(of: tweets)
                return
            }
            
            printTweets(tweets, displaysLengths: lengthFlag)
        })
}
main.run()
