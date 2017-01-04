# swtws

[Swift Tweets](https://swift-tweets.github.io/) の発表者用コマンドラインツールです。

## Tweet file format

[こちらのようなフォーマット](https://gist.github.com/koher/6707cd98ea3a2c29f58c0fdecbe4825c)で記述された発表ツイートのテキストファイルを用意して下さい。 Character encoding は **UTF-8 必須** です。

ファイルの拡張子は `.tw` が推奨です。

## How to build

このリポジトリをクローンし、 Swift Package Manager を使ってビルドします。

```bash
git clone https://github.com/swift-tweets/swtws.git
cd swtws
swift build
```

## How to use

上記の手順で `.build/debug/swtws` に `swtws` のバイナリができあがります。必要に応じてパスを通すなどして下さい。

`sample.tw` というファイルに対して、フォーマットのエラーなくパースに成功するかをチェックするには次のようにコマンドを実行します。

```bash
# パスを通した場合
swtws sample.tw

# パスを通さない場合
.build/debug/swtws sample.tw
```

`-c` または `--count` オプションでツイートの数を表示することができます。

```bash
swtws --count sample.tw
```

## Dependencies

依存関係は Swift Package Manager によって自動的に解決されます。

- [TweetupKit](https://github.com/swift-tweets/tweetup-kit)
