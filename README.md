# kuocr

画像文字起こし API のフロントエンド Web アプリケーション。

組織内の利用者を SAML/OIDC で認証し、ブラウザからアップロードされた画像を外部の文字起こし API（Ollama 互換）で処理して、結果（Markdown / テキスト形式）をダウンロードできます。

## システム構成

```
[ブラウザ] → [kuocr (本アプリ)] → [文字起こし API サーバ]
                 ↓
            [IdP (SAML/OIDC)]
```

- **kuocr**: フロントエンド Web サーバ（本リポジトリ）
- **文字起こし API**: 画像を POST すると Markdown 等で文字起こし結果を返す外部 API（Ollama 互換）
- **IdP**: 組織の ID プロバイダ（SAML または OIDC 対応）

## 主な機能

- 画像アップロード（複数ファイル対応）
- OCR 処理（外部 API 連携、ストリーミング対応）
- 結果のダウンロード（テキスト / Markdown 形式、ZIP 一括ダウンロード）
- ユーザー認証（ローカル認証 / SAML / OIDC）
- 管理者画面（OCR API 設定、認証設定、IdP 管理）

## 動作環境

- Ruby 3.4.9
- Ruby on Rails 8.1
- SQLite3（開発環境）/ PostgreSQL（本番環境）

## セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/aiuemon/kuocr.git
cd kuocr
```

### 2. Ruby のインストール

```bash
rbenv install 3.4.9
rbenv local 3.4.9
```

### 3. 依存関係のインストール

```bash
bundle install
```

### 4. データベースのセットアップ

```bash
bin/rails db:create db:migrate
```

### 5. サーバーの起動

```bash
bin/rails server
```

ブラウザで http://localhost:3000 にアクセスしてください。

## OCR API 設定

管理者画面 (`/admin/ocr_settings`) から以下の設定が可能です:

| 設定項目 | 説明 |
|----------|------|
| endpoint | API エンドポイント URL（例: `http://localhost:11434/api/generate`） |
| api_key | API 認証キー（Bearer トークン、任意） |
| timeout | リクエストタイムアウト（秒、デフォルト: 300） |
| model | VLM モデル名（例: `llava:latest`） |
| prompt | 文字起こし用プロンプト |
| options | temperature, num_predict 等の JSON オプション |

### Ollama を使用する場合

```bash
# Ollama のインストール後、VLM モデルをダウンロード
ollama pull llava

# Ollama サーバーを起動
ollama serve
```

エンドポイントに `http://localhost:11434/api/generate` を設定してください。

## 開発コマンド

```bash
# テスト実行
bin/rails test

# リント
bin/rubocop

# フォーマット
bin/rubocop -a

# アセットのプリコンパイル
bin/rails assets:precompile
```

## ライセンス

このプロジェクトは開発中です。
