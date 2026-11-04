# AS 航線分工執行器

備用 repo 負責香港與台北星宇航線（含回程），主 repo 負責其他日本相關航線。每四小時執行，與主 repo 錯開兩小時；台灣 02／06／10／14／18／22:17，GitHub 可能延遲。每批正常最多 20 次、恢復期 4 次，頭等優先。

兩邊讀取私人 claude-- main 程式及 award-data 共同待查／冷卻資料。下載資料前領取批次、成功保存才歸還，避免延遲排程互相覆寫。遇到網站驗證仍停止，不能換 repo 接著重試；分工不保證網站不再要求驗證。星宇現金價月更仍為獨立流程。

需 DATA_TOKEN 具 claude-- Contents 讀寫及 repository dispatch 權限。main push 只做狀態讀寫診斷，不呼叫航空網站。standby-check 仍保留只讀診斷。

Telegram「更多操作 → 執行器分工」可查看分工及設定下次手動人工協助 repo。Worker GH_TOKEN 另需此私有 repo 的 Actions 讀寫權限；無權限會明示，不冒稱已派工。
