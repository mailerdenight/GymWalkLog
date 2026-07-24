# App Store IAP Resubmission

## Files to use

- IAP review screenshot: [screenshots/iap-review/pro-review-screenshot-ipad.png](/Users/ac/Documents/ジム歩走ログ/screenshots/iap-review/pro-review-screenshot-ipad.png)
- Product ID in app: `com.gymwalklog.app.pro`
- Product type: `Non-Consumable`

## App Store Connect steps

1. Open `Apps` and select `ジム歩走ログ`.
2. Go to `Monetization` -> `In-App Purchases`.
3. Open `Pro` or create it as `Non-Consumable` if it doesn't exist yet.
4. Fill in the product metadata below.
5. Upload the App Review screenshot from this repo.
6. Confirm the IAP status becomes `Ready to Submit`.
7. Return to the app version you will resubmit.
8. In `In-App Purchases and Subscriptions`, select `Pro`.
9. Choose the new build and submit the app for review.

## Suggested IAP metadata

### Basic

- Reference Name: `Pro`
- Product ID: `com.gymwalklog.app.pro`
- Type: `Non-Consumable`

### Japanese localization

- Display Name: `Proアップグレード`
- Description: `記録上限解除・グラフ・写真無制限`

### English localization

- Display Name: `Pro Upgrade`
- Description: `Unlock logs, charts, unlimited photos`

## Review notes for the app version

### Japanese

今回の再提出では、アプリ内で案内している非消耗型 In-App Purchase `Pro`（Product ID: `com.gymwalklog.app.pro`）をアプリ本体の新しいビルドと一緒に審査へ追加しました。  
`Pro` は買い切り型で、31件目以降の記録保存、詳細グラフ、写真無制限、PDF/CSV出力、iCloud同期を解放します。  
審査用スクリーンショットも IAP 側に追加済みです。よろしくお願いいたします。

### English

In this resubmission, we included the non-consumable In-App Purchase `Pro` (Product ID: `com.gymwalklog.app.pro`) together with a new app build for review.  
`Pro` is a one-time purchase that unlocks saving more than 30 records, detailed charts, unlimited photos, PDF/CSV export, and iCloud sync.  
The App Review screenshot for this IAP has also been added. Thank you for your review.

## Reply to App Review message

### Japanese

ご連絡ありがとうございます。  
ご指摘いただいた `Pro` の In-App Purchase について、審査用スクリーンショットと必要なメタデータを追加し、アプリ本体の新しいビルドと合わせて再提出しました。  
今回の再提出には、非消耗型 IAP `com.gymwalklog.app.pro` が含まれています。よろしくお願いいたします。

### English

Thank you for the review and for pointing this out.  
We have now added the required metadata and App Review screenshot for the `Pro` In-App Purchase and resubmitted it together with a new app build.  
This resubmission includes the non-consumable IAP `com.gymwalklog.app.pro`. Thank you for your time.

## Quick checklist

- IAP `Pro` exists in App Store Connect
- IAP screenshot uploaded
- IAP status is `Ready to Submit`
- IAP selected in `In-App Purchases and Subscriptions`
- New binary uploaded
- Review note pasted
