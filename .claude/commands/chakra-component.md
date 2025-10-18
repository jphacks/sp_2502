---
argument-hint: [issue番号]
description: issueから共通UIコンポーネントを実装するためのコマンド
---

issue $1 から共通のUIコンポーネントを実装します。
以下の手順に従って実装を行います。

## 実装の流れ

### 1. Issue内容の確認
- `gh issue view $1` でissueの内容を確認する

### 2. ブランチの作成
- `git checkout main` でmainブランチに移動
- `git pull origin main` で最新のリモート状態を取得
- `git checkout -b claude/#$1/chakra-component/<簡潔な説明>` で新しいブランチを作成
  - 例: `claude/#456/chakra-component/add-card-list`

### 3. 実装
以下の規約に従って実装する:

#### ディレクトリ構造
- 共通コンポーネント: `src/components/<module>/<component-name>.tsx`
  - 例: `src/components/note/note-card.tsx`
  - 例: `src/components/common/loading-spinner.tsx`

#### コンポーネント設計
- プロップスの型定義を明確にする
- 再利用可能な粒度で実装する
- tRPCの呼び出しは含めない（親コンポーネントからpropsで受け取る）

#### スタイリング
- Chakra UI v3を使用
- 既存コンポーネント（`src/app/_components/notes.tsx`）を参考にする
- 必要に応じて、 Chakra UI の MCP サーバーを利用する
- 必要に応じて、 playwright の MCP サーバーを利用して画面の動作確認を行う

### 4. コミットの作成
- 適切な粒度でコミットを作成

### 5. PRの作成
- `gh pr create` でPRを作成
- PR descriptionは `.github/pull_request_template.md` のテンプレートに従う
- テンプレート内の項目を埋める

### 6. コードレビュー依頼
- PRのURLをユーザーに提示
