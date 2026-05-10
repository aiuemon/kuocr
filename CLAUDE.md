# kuocr

画像文字起こし API のフロントエンド Web アプリケーション。

組織内の利用者を SAML/OIDC で認証し、ブラウザからアップロードされた画像を外部の文字起こし API で処理して、結果（Markdown 等の複数フォーマット）をダウンロードできるようにする。

## システム構成

```
[ブラウザ] → [kuocr (本アプリ)] → [文字起こし API サーバ]
                 ↓
            [IdP (SAML/OIDC)]
```

- **kuocr**: フロントエンド Web サーバ（本リポジトリ）
- **文字起こし API**: 画像を POST すると Markdown 等で文字起こし結果を返す外部 API（Ollama 互換）
- **IdP**: 組織の ID プロバイダ（SAML または OIDC 対応）

## OCR API 設定

管理者画面 (`/admin/ocr_settings`) から以下の設定が可能:

| 設定項目 | 説明 |
|----------|------|
| endpoint | API エンドポイント URL（例: `http://localhost:11434/api/generate`） |
| api_key | API 認証キー（Bearer トークン、任意） |
| timeout | リクエストタイムアウト（秒、デフォルト: 300） |
| model | VLM モデル名（例: `llava:latest`） |
| prompt | 文字起こし用プロンプト |
| options | temperature, num_predict 等の JSON オプション |

### API リクエスト形式

Ollama 互換の JSON 形式でリクエスト:

```json
{
  "model": "モデル名",
  "prompt": "プロンプト",
  "images": ["Base64エンコード画像"],
  "stream": true,
  "options": { "temperature": 0.4, ... }
}
```

レスポンスは NDJSON（改行区切り JSON）形式のストリーミング。

## プロジェクトフェーズ

現在: **PROTOTYPE**

| フェーズ | 意味 | 状態 |
|---|---|---|
| **PROTOTYPE** | 試作期 | 試作・検証中。コア機能の開発とプロトタイピング |
| **ALPHA / BETA** | 検証期 | 主要機能が揃い、フィードバック収集・改善中 |
| **PREVIEW** | 公開準備期 | 本番環境に近い状態で最終調整 |
| **STABLE** | 安定稼働期 | 正式リリース。安定稼働中 |

## 言語・ツール

- 言語: Ruby 3.4.9 (rbenv)
- フレームワーク: Ruby on Rails
- DB:
  - 開発環境: SQLite3
  - 本番環境: PostgreSQL
- ビルド: `bin/rails assets:precompile`
- テスト: `bin/rails test`
- リント: `bin/rubocop`
- フォーマット: `bin/rubocop -a`

## コーディング規約

- コーディングスタイルガイド: [Ruby Style Guide](https://rubystyle.guide/)
- フォーマッタ/リンタ: Rubocop
- 命名規則:
  - クラス・モジュール: PascalCase (`UserAccount`, `PaymentService`)
  - メソッド・変数: snake_case (`find_user`, `user_name`)
  - 定数: SCREAMING_SNAKE_CASE (`MAX_RETRY_COUNT`)
  - ファイル名: snake_case (`user_account.rb`)

### Rails 固有の規約

- コントローラ: 複数形 (`UsersController`)
- モデル: 単数形 (`User`)
- ビュー: `app/views/コントローラ名/アクション名.html.erb`
- パーシャル: `_` プレフィックス (`_form.html.erb`)
- マイグレーション: タイムスタンプ付きファイル名

## 開発フロー

1. **Issue 作成** — コード・ドキュメント等の変更には必ず Issue を作成する
   - Issue のコメントに調査内容・試行錯誤・判断の経緯を記録する
   - 適宜ラベルを付与する
   - `backlog` ラベル: 優先度が低く、通常の開発サイクルでは取り組まない Issue に付与する。「オープンの Issue に取り組んで」等の指示では `backlog` ラベルの Issue は対象外とする
2. **設計** — 設計チームが要件整理・アーキテクチャ設計を行い、Issue に設計内容を記載する
3. **設計レビュー** — レビューチームが設計の妥当性をチェックし、設計チームと相談・調整する
4. **ブランチ作成** — git worktree を使い、Issue に紐づくブランチで作業する
   - ブランチ命名規則: `issue-<番号>/<簡単な説明>` (例: `issue-42/add-user-auth`)
5. **実装** — 実装チームが設計に基づきコーディングする
   - 不明点は設計チーム・レビューチームに相談する
6. **PR 作成** — Issue を参照する (`Closes #42` 等)
7. **コミット・プッシュ** — 作業中は適宜 commit・push を行う（main ブランチへの直接 push は禁止）
8. **コードレビュー** — マージ前にレビューチームが PR をレビューする
9. **マージ** — squash merge を使用する
10. **ブランチ削除** — マージ後にブランチを自動削除する

## チーム解散前の必須チェック

チームを解散する前に、必ず以下の 3 つの検証を実施すること:

1. **設計との乖離チェック** — ドキュメント（CLAUDE.md, README.md 等）と実装コードに乖離がないか
2. **テストの不足チェック** — 新規・変更コードに対してテストが十分か、カバレッジに穴がないか
3. **ドキュメントの不足チェック** — 新機能・変更がドキュメントに反映されているか

発見された問題は Issue 化して対応してから解散する。

## Dependabot PR 対応方針

GitHub Dependabot が依存更新の PR を自動作成する。以下の基準で緊急度を判断し対応する。

| 緊急度 | 条件 | 対応 |
|--------|------|------|
| **即対応** | セキュリティ脆弱性修正（CVE あり、severity: high/critical） | 最優先でビルド・テスト確認後マージ |
| **早めに対応** | セキュリティ修正（severity: moderate/low）、メジャーバージョンアップ | 破壊的変更の有無を確認し、必要なら手動修正して対応 |
| **通常対応** | マイナー/パッチバージョン更新、dev 依存のみの更新 | 通常の開発サイクルで対応 |

### 対応手順

1. Dependabot PR の changelog・破壊的変更を確認する
2. ライセンスが permissive であることを確認する
3. 破壊的変更がある場合は Dependabot PR をベースにせず、新しいブランチで手動対応する
4. テスト・リント・フォーマットチェックの通過を確認する
5. マージ後、元の Dependabot PR が自動クローズされない場合は手動でクローズする

## ライセンスルール

- GPL 系ライセンスの依存ライブラリは使用禁止（商用転用の可能性があるため）
- 許可: MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC, Zlib 等の permissive ライセンス
- 依存追加時はライセンスを必ず確認する

## 環境ルール

- sudo は使用しない
- Ruby のバージョン管理には rbenv を使用する
- サービスやミドルウェアが必要な場合は Docker を使用し、`docker-compose.yaml` で管理する

## 言語ルール

- Issue、コメント、PR の説明、コミットメッセージなど自然言語を書く箇所はすべて日本語で記述する
