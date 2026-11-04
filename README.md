# AS 哩程備用執行器

目前階段：只讀啟動檢查，尚未啟用航空掃描。

沒有 cron。push main 或 Actions 手動執行會讀取正式 main 程式、award-data 共用狀態，使用正式 scan_preflight.py 檢查冷卻。沒有航空查詢、瀏覽器安裝、票況寫回或 Telegram 通知。Actions 成功只代表基礎檢查成功。

## 建立方式

1. 在 GitHub 建立空白 `EDDIELI-coder/as-award-scanner-backup`。
2. 將本目錄的全部檔案（含隱藏的 `.github`）推到 main。
3. 在新 repo Settings → Secrets and variables → Actions 設定 `DATA_TOKEN`，允許讀取私人 `claude--`。不要將 Token 貼入對話或程式。
4. Actions → 備用執行器檢查 → Run workflow。首次 push 若尚無 Secret 應明確失敗，設定後重跑。

## 真正接替前

此檢查包未提供航空掃描工作。切換需先停用主工作並確認沒有執行／排隊，再處理 Worker 派送目的地及 OIDC repo 白名單，安裝正式掃描 workflow，保留共用冷卻與待查清單。

GitHub concurrency 只作用於同 repo，兩邊相同 group 不會防止同時掃描。不能把原 scan.yml 原封不動在兩邊啟用；原本的「保持排程啟用」也不能帶進待命 repo。

本機驗證：`python -m unittest -q`。本機測試不是 GitHub 或航空官網試跑成功。
