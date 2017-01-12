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

## How to update

`swtws` コマンドをアップデートするには最新版を `git pull` してビルドするだけでなく、依存ライブラリも確実にアップデートするために、ビルド前に `swift build --clean` および `swift build --clean dist` を実行して下さい。

```bash
git pull
swift build --clean
swift build --clean dist
swift build
```

## How to get tokens

`swtws` を使って Twitter や Gist に投稿するためには各種 token を取得する必要があります。

### Twitter

次の四つが必要です。

- Consumer Key
- Consumer Secret
- Access Token
- Access Token Secret

取得方法については下記ページが参考になります。

- [TWITTERでOAUTH認証を行う(1：TWITTERへのアプリケーション登録)](http://techbooster.org/android/mashup/4525/)
- [Tokens from dev.twitter.com](https://dev.twitter.com/oauth/overview/application-owner-access-tokens)

### GitHub

Personal Access Token が必要です。下記ページの手順で取得可能です。

- [Creating an access token for command-line use](https://help.github.com/articles/creating-an-access-token-for-command-line-use/)

## How to upload resources in advance

プレゼンテーション本番での技術的な失敗を可能な限り減らすために、事前にリソースをアップロードしておくことをオススメします。

### Post codes to Gist

`--resolve-code` オプションを使って tw ファイルに記述されたコードを事前に Gist に投稿することができます。 Gist に投稿するには `--github` オプションで GitHub の [Personal Access Token](https://github.com/settings/tokens) を指定する必要があります。下記の例では `ffffffffffffffffffffffffffffffffffffffff` が Access Token に当たります。

tw ファイル中のコードをリンクと画像に置き換えた結果が標準出力に書き出されるので、 `> path/to/output.tw` のようにして結果を保存して下さい。

```bash
swtws path/to/tweets.tw --resolve-code --github ffffffffffffffffffffffffffffffffffffffff > path/to/output.tw
```

### Upload images to Twitter

`--resolve-image` オプションを使って tw ファイルに記述された画像を事前に Twitter にアップロードすることができます。 Twitter にアップロードするには `--twitter` オプションで [Consumer Key, Consumer Secret, Access Token, Access Token Secret](https://dev.twitter.com/oauth/overview/single-user) を `,` 区切りで指定する必要があります。下記の例ではそれぞれ `WWWWWWWWWWWWWWWWWWWW`, `XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`, `YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY`, `ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ` に当たります。

tw ファイル中のコードをリンクと画像に置き換えた結果が標準出力に書き出されるので、 `> path/to/output.tw` のようにして結果を保存して下さい。

```bash
swtws path/to/tweets.tw --resolve-image --twitter WWWWWWWWWWWWWWWWWWWW,XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY,ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ > path/to/output.tw
```

## Dependencies

依存関係は Swift Package Manager によって自動的に解決されます。

- [TweetupKit](https://github.com/swift-tweets/tweetup-kit)
