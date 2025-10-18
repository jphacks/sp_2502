---
argument-hint: [issue番号]
description: sub-agentを用いてissueから新しいユースケースを実装するためのテンプレート
---

sub-agent「usecase-maker」を用いてissue $1 から新しいユースケースを実装します。
以下の手順に従って実装を行います。

## 実装の流れ

### 1. Issue内容の確認
- `gh issue view $1` でissueの内容を確認する

### 2. ブランチの作成
- `git checkout main` でmainブランチに移動
- `git pull origin main` で最新のリモート状態を取得
- `git checkout -b <適切なブランチ名>` で新しいブランチを作成
  - ブランチ命名規則: `claude/#$1/usecase/<簡潔な説明>`（例: `claude/#123usecase//add-note-create`）

### 3. 実装
- sub-agent「usecase-maker」を呼び出し、実装する

### 4. コミットの作成
- 適切な粒度でコミットを作成:
  - スキーマ変更、リポジトリ実装、エンドポイント実装などを分ける）

### 5. PRの作成
- `gh pr create` でPRを作成
- PR descriptionは `.github/pull_request_template.md` のテンプレートに従う
- テンプレート内の項目を埋める

### 6. コードレビュー依頼
- PRのURLをユーザーに提示
