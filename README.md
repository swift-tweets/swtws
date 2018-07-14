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
swtws check sample.tw

# パスを通さない場合
.build/debug/swtws check sample.tw
```

`-c` または `--count` オプションでツイートの数を表示することができます。

```bash
swtws check --count sample.tw
```

実際に Twitter に投稿するには `swtws presentation` を実行します。

```bash
swtws presentation sample.tw --twitter ... sample.tw
```

なお、少なくとも `--twitter` の指定が必要です。このオプションの指定方法は、「[Upload images to Twitter](#upload-images-to-twitter)」を参照してください。また、Twitter への投稿と同時に Gist への投稿と画像化を済ませるならば、`--github` の指定も必要です（ただし、[事前にリソースをアップロードしておくことを推奨します](#how-to-upload-resources-in-advance)）。これらのオプションを使ってトークンを指定する方法の詳細は [How to upload resources in advance](#how-to-upload-resources-in-advance) を御覧下さい。

デフォルトでは 30 秒間隔でツイートされますが、 `--interval` オプションを使って間隔を変更することもできます。たとえば、 15 秒間隔にするには次のように指定します。

```bash
swtws presentation --interval 15.0 --twitter ... sample.tw
```

## How to update

`swtws` コマンドをアップデートするには最新版を `git pull` してビルドするだけでなく、依存ライブラリもアップデートするために、ビルド前に `swift package update` を実行して下さい。

```bash
git pull
swift package update
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

事前処理は三つのステップに分かれており、それぞれ `resolve-code`, `resolve-gist`, `resolve-image` のサブコマンドを利用します。一つのステップごとにアップロードしたリソース等を直接利用できるように tw ファイルが書き変えられます。ここでは、次のような tw ファイルがあったとして、それがどのように書き変えられるかを例示します。

    例：この tw 形式のツイートがどのように変化するか示します。

    ```swift:hello.swift
    print("Hello")
    ```

### Post codes to Gist

`swtws resolve-code` コマンドを使って tw ファイルに記述されたコードを事前に Gist に投稿することができます。 Gist に投稿するには `--github` オプションで GitHub の [Personal Access Token](https://github.com/settings/tokens) を指定する必要があります。下記の例では `ffffffffffffffffffffffffffffffffffffffff` が Access Token に当たります。

tw ファイル中のコードをリンクと画像に置き換えた結果が標準出力に書き出されるので、 `> path/to/output.tw` のようにして結果を保存して下さい。

```bash
swtws resolve-code --github ffffffffffffffffffffffffffffffffffffffff path/to/tweets.tw > path/to/output.tw
```

    例：この tw 形式のツイートがどのように変化するか示します。

    https://gist.github.com/0000000000000000000000000000000000000000

    ![](gist:0000000000000000000000000000000000000000)

### Write codes on Gist as images

`swtws resolve-gist` コマンドを使って tw ファイルに記述された `![](gist:0000000000000000000000000000000000000000)` 形式の画像を生成し、ローカルファイルとして保存することができます。保存先ディレクトリを `--image-output` オプションで指定する必要があります。

tw ファイル中の `![](gist:0000000000000000000000000000000000000000)` を `![](output/directory/path/image.png)` に置き換えた結果が標準出力に書き出されるので、 `> path/to/output.tw` のようにして結果を保存して下さい。

```bash
swtws resolve-gist --image-output output/directory/path path/to/tweets.tw > path/to/output.tw
```

    例：この tw 形式のツイートがどのように変化するか示します。

    https://gist.github.com/0000000000000000000000000000000000000000

    ![](output/directory/path/image.png)

### Upload images to Twitter

`swtws resolve-image` コマンドを使って tw ファイルに記述された画像を事前に Twitter にアップロードすることができます。 Twitter にアップロードするには `--twitter` オプションで [Consumer Key, Consumer Secret, Access Token, Access Token Secret](https://dev.twitter.com/oauth/overview/single-user) を `,` 区切りで指定する必要があります。下記の例ではそれぞれ `WWWWWWWWWWWWWWWWWWWW`, `XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`, `YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY`, `ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ` に当たります。

tw ファイル中のコードをリンクと画像に置き換えた結果が標準出力に書き出されるので、 `> path/to/output.tw` のようにして結果を保存して下さい。

```bash
swtws resolve-image --twitter WWWWWWWWWWWWWWWWWWWW,XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX,YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY,ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ path/to/tweets.tw > path/to/output.tw
```

    例：この tw 形式のツイートがどのように変化するか示します。

    https://gist.github.com/0000000000000000000000000000000000000000

    ![](twitter:999999999999999999)
