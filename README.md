[English](./README_en.md)

# プロジェクトテンプレートの利用
このリポジトリの画面右上にある`Use this template`ボタンを押して、`Create a new repository`を選択する。あとはいつも通り。このリポジトリの画面を開かずとも、ABEJA organizationで新しくリポジトリを作成する際にテンプレートを選択出来るようになっているので、このテンプレートを選択する。

# Dockerコンテナのセットアップ
## Specify Python version
`context/<cpu or gpu>`配下の`docker-compose.yml`でPythonのバージョンを指定する。Jupyter Labを使用する場合は`ports`のコメントアウトを外してMakefile内の`start-jupyter`コマンドのポートを`docker-compose.yml`のポートに合わせる。デフォルトでポート8888を使うため、DGXなどの共通利用のマシン上で起動する場合などは空いているポートを確認し、`docker-compose.yml`の`ports`のソースを変更する（`start-jupyter`コマンドのport指定も同様に変更する）。


## Build & Run docker container
以下のコマンドを実行してイメージ作成、Dockerコンテナを立ち上げる。このコマンドによって`.env_project`が生成される。この`.env_project`を環境変数ファイルとして`docker-compose.yml`で使用している。

With cpu
```
make init-docker-cpu
```

With gpu
```
make init-docker-gpu
```

# 分析環境のセットアップ
## For VSCode
### Connect into docker container with VSCode
VSCodeの`Dev Containers`拡張機能で立ち上げたコンテナにVSCodeをアタッチする

### Setup VSCode
コンテナ内で以下のコマンドを実行してVSCodeの最低限の拡張機能をインストールする
```
# If you use stable VSCode
make setup-vscode

# If you use VSCode Insiders
make setup-vscode-insiders
```

## For JupyterLab
ローカル環境であれば以下のコマンドを実行してJupyter Labを起動する。
```
make start-jupyter
```

起動したら[http://127.0.0.1:8888/lab](http://127.0.0.1:8888/lab)にアクセスする。ポートを変えている場合は適宜8888の部分を変更する。また、DGXなどの共有マシンで起動する場合は以下のようにSSHポートフォワーディングしてから上記に接続する。
```
$ ssh -N -L 8888:localhost:{コンテナと繋がっているDGXのポート番号} dgx1a
```

ホストOSがWindowsの場合は`%USERPROFILE%/.wslconfig`を作成し、以下を記載する。（作成後、WSLを一度shutdownする）
```
[wsl2] 
localhostForwarding=true
```

終了したらJupyterLabをshutdownする。JupyterLabのGUIからshutdownしてもいいし、以下のコマンドでコンテナを停止してもいい。
```
make docker-stop
```

もしくは、Jupyter Labだけ落としたい場合は以下のコマンドでもOK。

```
make stop-jupyter
```

# Install Python packages

仮想環境の作成とパッケージのインストールをする

```bash
uv sync  # すべてのグループを同期する（基本的にはこれを実行する）
uv sync --dev  # devグループのパッケージを同期する
uv sync --no-dev  # devグループ以外のパッケージを同期する
uv sync --group <group_name1> --no-group  <group_name2>  # 特定のグループを同期、特定のグループを同期しない
```

プロジェクトの依存関係を更新するには下記などを実行する：

```bash
uv add <package_name>  # パッケージを追加する
uv add <package_name> --group <group_name>  # 特定のグループにパッケージを追加する
uv add <package_name> --dev  # devグループにパッケージを追加する
uv add --editable <path_to_package>  # ローカルのパッケージをeditableモードで追加する
uv remove <package_name>  # パッケージを削除する
```

詳細は https://docs.astral.sh/uv/concepts/projects/dependencies/ を参考にされたい。

※ なお、project_module の依存関係を更新したい場合は `./project_module` に移動したのちに `uv add` などを実行すればよい。

# abeja-toolkitの同期

abeja-toolkitは以下のコマンドで最新版に同期したり、新しいツールを追加することが出来ます。

```shell
chmod +x ./scripts/sync_tools.sh # 1回実行すればOK
./scripts/sync_tools.sh [<tool1> <tool2> ...]
```

もし、abjea-toolkit の特定のバージョンを同期したい場合は、以下のように`--version`オプションをつけて実行します。

```shell
./scripts/sync_tools.sh [<tool1> <tool2> ...] --version <version>
```

詳しくは

```shell
./scripts/sync_tools.sh --help
```

を参照してください。

# dsg-project-template の同期

dsg-project-templateは以下のコマンドで最新版に同期することが出来ます。

```shell
chmod +x ./scripts/sync_dsg-project-template.sh # 1回実行すればOK
./scripts/sync_dsg-project-template.sh [--version <version:branch or tag>] [--debug]
```

もしくは

```shell
make sync-template VERSION=<version:branch or tag>
```

詳細は`./scripts/sync_dsg-project-template.sh --help`を参照してください。

# ディレクトリ構成
このリポジトリは以下のディレクトリで構成されています。

- .github: GitHub workflowなど
    - [pull_request_template.md](./.github/pull_request_template.md): PRテンプレートの設定ファイル
    - workflows
        - [lint.yaml](./.github/workflows/lint.yaml): DockerfileのlintとPythonパッケージのlintを行うworkflowの設定ファイル
            - lint_python_scriptsについて
                - ベースコミットと比較して差分のあるPythonスクリプトを含むPythonパッケージに対してlintを実行します。
                - 差分が無い場合はlintは実行されません。
- [.vscode](./.vscode): VSCode利用時のsettingsファイル
    - [settings.json](./.vscode/settings.json): 適宜設定を変更してください。formatOnSaveはデフォルトでoffになっています
- context: Dockerfileと、CPU、GPU環境向けのdocker-compose.ymlがそれぞれ格納されています。
    - [Dockerfile](./context/Dockerfile)
    - [.hadolint.yaml](./context/.hadolint.yaml)
    - cpu
        - [docker-compose.yml](./context/cpu/docker-compose.yml)
    - gpu
        - [docker-compose.yml](./context/gpu/docker-compose.yml)
- experimentation: 実験用のnotebookやデータセット、出力を格納するディレクトリ
    - [dataset](./experimentation/dataset/): データセットを配置するディレクトリ
    - [latest](./experimentation/latest/): 最新の実験パラメータや結果を格納するディレクトリ
    - [notebooks](./experimentation/notebooks/): 実験用notebookを配置するディレクトリ
    - [outputs](./experimentation/outputs/): 実験の出力を格納するディレクトリ
- libs: プロジェクト固有ではないモジュールやgit submoduleを置いておく場所
    - [abeja-toolkit](./libs/abeja-toolkit/): ABEJAの社内Pythonライブラリの一部。デフォルトでは以下のツールが含まれている。
        - [notebook_exporter](./libs/abeja-toolkit/notebook_exporter/): notebookをNotionページに変換するツール
        - [notion_extension](./libs/abeja-toolkit/notion_extension/): Notion APIをハンドリングするツール
        - [spreadsheet](./libs/abeja-toolkit/spreadsheet/): スプレッドシートのデータを読み込んだり、スプレッドシートにデータを書き込むツール
- [project_module](./project_module/): プロジェクト固有のモジュールを実装するPythonパッケージテンプレート。このPythonパッケージをeditableモードでinstallし、importして使用します。スクリプトは適宜追加してください。
    - [tests](./project_module/tests/): 単体テストなどのテストモジュールを実装する
    - src
        - [project_module](./project_module/src/project_module/): この配下にスクリプトを格納していく
    - [pyproject.toml](./project_module/pyproject.toml): `project_module`の依存関係を記述するファイル
    - [README.md](./project_module/README.md): `project_module`の利用法を記載したファイル
- [pyproject.toml](./pyproject.toml): ルートディレクトリ直下のpyproject.toml。ここには開発用パッケージの依存関係などを定義する。
- README.md: このプロジェクトテンプレートの利用方法を記載しているファイル
- README_en.md: プロジェクトテンプレートの利用方法（英語版）


# Linting
devグループの依存関係をinstallしていれば、mypyとruffのlintチェックが以下のコマンドで実行出来ます。

```shell
make lint /path/to/module
```

# NotebookをNotionページに変換する
認証などを済ませて以下のコマンドを実行すると、指定したタイトルのNotionページが自動で生成され、notebook内のMarakdownセルとセル出力がNotionブロックに変換されます。詳細な利用方法は`notebook_exporter`の[README.md](./libs/abeja-toolkit/notebook_exporter/README.md)をご確認ください。

```
make to-notion /path/to/notebook.ipynb <notion_page_title>
```

# Notebookの出力を消す

Notebookのセル出力に機密情報を含む場合、GitHubにpushする前に出力を消すことを推奨します。以下のコマンドで一括で指定したディレクトリ配下のnotebook出力を削除することが出来ます。

```
make reset-notebook /path/to/directory/
```

# 自動テストについて
自動テストを実施したい場合、以下の情報を手掛かりにしてください。

- テストコードの配置場所とテストコードファイル名
    - **`project_module/tests`** にテストコードを配置してください。
    - テストコードファイルは **`test_*.py`** という形式で命名してください。
- テストコードの設定ファイル
    - (root)/pytest.ini に定義が記述されています。
        - デフォルトでは、以下の引数が追加されるようになっています。
            - **`-v`**: 詳細な出力（verbose）を有効にします。テストの実行状況がより詳しく表示されます。
            - **`--strict-markers`**: 登録されていないマーカーが使用された場合に警告ではなくエラーを発生させます。これにより、typoによるマーカー名のミスなどを防げます。
            - **`--cov=project_module/src/project_module`**: テストのカバレッジ（コード網羅率）を計測する対象として、`project_module/src/project_module` ディレクトリを指定しています。
            - **`--cov-branch`**: ブランチカバレッジ（条件分岐の網羅率）も計測します。
            - **`--cov-report=term-missing`**: カバレッジのレポートをコンソールに出力する形式を指定しています。`term-missing` は、カバレッジが不足している行を表示する形式です。
- テスト実行コマンド
    - `make test` でテストを実行します。
        - テストコードが配置されているパスを引数に指定することができます。
            - `make test (テスト対象のパス）`
        - 注意： pytest の標準動作では、テストが1件も収集されなかった場合の終了コードは 5 です。本プロジェクトでは `./conftest.py` の pytest フックにより、このケースを 警告を表示したうえで成功 (終了コード 0) とみなすように設定しています。挙動を変更したい場合は `./conftest.py` のフックを編集してください。
- github workflow の定義
    - `.github/workflows/test.yaml` で定義しています。
        - pushおよびpull request時に、変更があったpythonパッケージに対して自動テストが実施されます。
        - 最新のUbuntu環境下で、python3.10を用いて自動テストが実施されます。


# Issue/PRの発行をSlackに通知する

1. Slack Appにアクセスし、通知用のBotを作成する。
2. App管理画面の左側のナビゲーションメニューから`Incoming Webhooks`を選択し、Webhookを有効化する。
3. 画面を下にスクロールし、Webhookの作成申請を発行する（組織の管理者に申請する必要がある）
4. 申請が承認されたらwebhookを作成する
5. WebhookのURLをリポジトリのGitHub Repository Secretsに`SLACK_WEBHOOK_URL`の名前で設定する。

# Troubleshooting

- [Case: `make init-docker-cpu`や`make init-docker-gpu`を実行時に `~/.gitconfig` もしくは `~/.ssh` がないとエラーが出る](https://github.com/abeja-inc/dsg-project-template/wiki/Troubleshooting#case-make-init-docker-cpu%E3%82%84make-init-docker-gpu%E3%82%92%E5%AE%9F%E8%A1%8C%E6%99%82%E3%81%AB-gitconfig-%E3%82%82%E3%81%97%E3%81%8F%E3%81%AF-ssh-%E3%81%8C%E3%81%AA%E3%81%84%E3%81%A8%E3%82%A8%E3%83%A9%E3%83%BC%E3%81%8C%E5%87%BA%E3%82%8B)

- [Case: `sudo make init-docker-cpu` や`sudo make init-docker-gpu`を実行時に `useradd: user 'root' already exists` というメッセージとともにエラーが生じる。](https://github.com/abeja-inc/dsg-project-template/wiki/Troubleshooting#case-sudo-make-init-docker-cpu-%E3%82%84sudo-make-init-docker-gpu%E3%82%92%E5%AE%9F%E8%A1%8C%E6%99%82%E3%81%AB-useradd-user-root-already-exists-%E3%81%A8%E3%81%84%E3%81%86%E3%83%A1%E3%83%83%E3%82%BB%E3%83%BC%E3%82%B8%E3%81%A8%E3%81%A8%E3%82%82%E3%81%AB%E3%82%A8%E3%83%A9%E3%83%BC%E3%81%8C%E7%94%9F%E3%81%98%E3%82%8B)

# Contributing

## 自動ラベリングとブランチプレフィックスの補足

詳細なブランチ運用方針はプロジェクト Wiki の「[Development Guide](https://github.com/abeja-inc/dsg-project-template/wiki/Development-Guide)」を参照してください。ここでは、自動ラベリング／バリデーションに関する追加ルールのみ補足します。

- Pull Request のターゲットは `main` / `develop` / `release/**` のいずれかに限定され、ブランチ名は既定のプレフィックスを満たさないと `Branch Name Verifier` ワークフローで失敗します。
- 許可されているプレフィックス（`prefix/短い要約` または `prefix-短い要約` 形式）  
  - `feat/` または `feature/` … 新機能 → `feature` ラベル  
  - `fix/` … バグ修正 → `bug`  
  - `doc/` … ドキュメント更新 → `documentation`  
  - `change/` / `rename/` … 仕様変更・破壊的変更 → `change`  
  - `refactor/` / `style/` / `chore/` … リファクタ・整形・雑多な更新 → `other`  
  - `test/` … テストコード更新 → `enhancement` または `other`  
  - `dep/` / `dependabot/` … 依存関係の更新 → `dependencies`  
  - `release/` … リリースブランチ用（対象: `release/**` のみ）

- `.github/workflows/**` を変更した場合はファイルマッチで `cicd` ラベルが自動付与されます。`pyproject.toml` / `poetry.lock` / `uv.lock` / `requirements*.txt` を含む場合は `dependencies` が付与されます。
- これらの判定は `Release Drafter and PR Auto Labeler` ワークフローと `Branch Name Verifier` ワークフローにより自動化されています。ルールに合わないブランチ名やターゲットを指定すると PR 作成時にエラーとなるため、必要に応じてブランチ名をリネームしてください。