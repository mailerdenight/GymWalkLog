# ジム歩走ログ App Store 公開メモ

最終更新: 2026-07-25

## 現在のビルド

- App名: ジム歩走ログ
- Bundle ID: `com.gymwalklog.app`
- バージョン: `1.3`
- ビルド番号: `6`
- App本体の価格: `Free` にする
- 追加課金: App内課金 `Pro`（非消耗型）で設定する
- 最新アーカイブ: [/private/tmp/GymWalkLog-1.3-6-final.xcarchive](/private/tmp/GymWalkLog-1.3-6-final.xcarchive)
- App Store Connect: 1.2は配信から削除済み。1.3（ビルド6）は審査待ちで、優先審査も受付済み

## 申請用テキスト案

### サブタイトル

トレッドミル専用の運動記録

### プロモーションテキスト

ジムでのウォーキングやランニングを、写真つきで手早く記録。距離・時間・消費カロリーをまとめて残せます。

### キーワード

トレッドミル,ウォーキング,ランニング,ジム,運動記録,歩数,距離,カロリー,フィットネス,習慣化

### 説明文

ジムでのウォーキングやランニングを、写真つきで気軽に残せるトレッドミル専用ログアプリです。

主な機能

- 距離・時間・消費カロリーをまとめて記録
- トレッドミル画面の写真を記録に添付
- 写真から数値の自動読み取りに対応
- カレンダーと一覧で日々の運動を振り返り
- 月ごとの回数や距離、カロリーを集計
- 平均速度や継続状況を見やすく表示

こんな方におすすめです

- ジムでの有酸素運動を続けたい
- トレッドミルの結果を手早く残したい
- 歩いた日も走った日も一緒に管理したい
- 月ごとの積み上がりを見ながら習慣化したい

無料版でも気軽に始められ、必要に応じて Pro で記録件数の上限拡張、写真保存、グラフ、PDF・CSV出力が使えます。

### 新機能

- バージョン1.1から1.2への更新後に記録が表示されなくなる問題を修正
- 旧保存先の記録と写真を安全にバックアップして自動復元
- 復元に失敗した場合は空の記録画面を表示せず、元データを保護
- Pro版のiCloud同期を修正
- 販売中バージョンから記録と写真を保持したまま更新できるデータ移行を追加
- iCloudが一時的に利用できない場合も端末内保存を継続
- トロフィー表示と通知を改善
- 記録削除時とウィジェット表示の安定性を改善

## サポート・プライバシー

- サポートURL: `https://mailerdenight.github.io/gym-walk-log/support/`
- プライバシーポリシーURL: `https://mailerdenight.github.io/gym-walk-log/privacy/`
- サポートメール: `mailerdenight@gmail.com`

## スクリーンショット候補

- [197AEA11-479B-4514-9846-6CC2F96FAEEE.png](../AppStoreAssets/Screenshots/appstore/197AEA11-479B-4514-9846-6CC2F96FAEEE.png)
- [29FEB34B-55E1-420F-9C54-2A8AC0DAD6F1.png](../AppStoreAssets/Screenshots/appstore/29FEB34B-55E1-420F-9C54-2A8AC0DAD6F1.png)
- [43E55F68-DF60-4254-A963-0AFF2872E8AA.png](../AppStoreAssets/Screenshots/appstore/43E55F68-DF60-4254-A963-0AFF2872E8AA.png)
- [450DEA2E-694F-4372-9D73-FEDE6B9B3545.png](../AppStoreAssets/Screenshots/appstore/450DEA2E-694F-4372-9D73-FEDE6B9B3545.png)
- [9E18803E-A11F-4C3C-B306-60CACC0E29B4.png](../AppStoreAssets/Screenshots/appstore/9E18803E-A11F-4C3C-B306-60CACC0E29B4.png)
- [DA7BF675-5D69-4CD7-B68A-B5A034012C0D.png](../AppStoreAssets/Screenshots/appstore/DA7BF675-5D69-4CD7-B68A-B5A034012C0D.png)

## 審査メモ案

- アプリはトレッドミルでの運動記録を保存するために、カメラ、写真ライブラリ、通知を使用します。
- カメラはトレッドミル画面の撮影に使用します。
- 写真ライブラリは、記録への写真追加と、撮影写真の保存に使用します。
- 通知は、運動記録の継続をやさしく促すリマインドに使用します。
- アカウント作成は不要です。

## リリース前チェック

- [ ] `mailerdenight@gmail.com` が実際に受信できる
- [ ] `https://mailerdenight.github.io/gym-walk-log/support/` を公開済み
- [ ] `https://mailerdenight.github.io/gym-walk-log/privacy/` を公開済み
- [ ] App Store Connect の `Pricing and Availability` で App本体が `Free` になっている
- [ ] App Store Connect の年齢区分とプライバシー回答を入力済み
- [ ] アプリ内課金 `Pro` の商品情報が App Store Connect 側で審査提出可能
- [x] CloudKit DevelopmentスキーマをProductionへ反映済み
- [x] 公開版1.1から記録・写真入りストアを上書き更新し、データの自動復元を確認
- [x] 公開版1.2で追加した記録と旧保存先の記録が統合されることを確認
- [x] App Storeで1.2を配信から削除
- [ ] 実機でカメラ撮影、アルバム追加、OCR、購入復元、ウィジェットを最終確認
- [x] 最新アーカイブ [/private/tmp/GymWalkLog-1.3-6-final.xcarchive](/private/tmp/GymWalkLog-1.3-6-final.xcarchive) からアップロード
- [x] 1.3（ビルド6）をApp Reviewへ提出
- [x] 重大なデータ表示問題の修正として優先審査を申請し、受付を確認

## アップロード手順

1. Xcode Organizer で [/private/tmp/GymWalkLog-1.3-6-final.xcarchive](/private/tmp/GymWalkLog-1.3-6-final.xcarchive) を開く
2. `Distribute App` を選ぶ
3. `App Store Connect` を選ぶ
4. `Upload` を進める
5. App Store Connect の `Pricing and Availability` で App本体価格が `Free` か確認する
6. App Store Connect でビルドを選択し、説明文、スクリーンショット、審査情報を確定して申請する
