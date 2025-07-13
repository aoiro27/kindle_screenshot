-- ページ数
set pages to 265
-- 対象アプリ
set target to "Kindle"
-- 保存フォルダ
set savepath to "~/Desktop/screenshot/"
-- 開始ファイル番号
set spage to 1
-- めくり方向(1=左 2=右)
set pagedir to 1
-- ページめくりウエイト(秒)
set pausetime to 2.0
-- 切り抜きサイズ(中心から)
set cropx to 0
set cropy to 0
-- リサイズ横(切り抜く前のサイズ換算=画面横/切り抜き横*仕上がり横)
set resizew to 0

-- デバッグ用：ログファイル
set logFile to "~/Desktop/kindle_debug.log"
do shell script "echo '=== Kindleスクリーンショットデバッグ開始 ===' > " & logFile

-- 処理開始通知を表示
if pagedir is 1 then
    set directionText to "左矢印キー"
else
    set directionText to "右矢印キー"
end if
display dialog "Kindleスクリーンショット処理を開始します。

設定内容:
• 処理ページ数: " & pages & "ページ
• 保存フォルダ: " & savepath & "
• ページ送り方向: " & directionText & "
• ページ送り待機時間: " & pausetime & "秒

処理中はKindleアプリを操作しないでください。" buttons {"開始", "キャンセル"} default button "開始" with title "Kindleスクリーンショット開始" with icon note

-- キャンセルされた場合は終了
if button returned of result is "キャンセル" then
    do shell script "echo 'ユーザーによりキャンセルされました' >> " & logFile
    return
end if

-- 保存フォルダを作成
do shell script "mkdir -p " & savepath

-- Kindleアプリを起動してアクティブにする
if target is not "" then
    tell application target
        activate
    end tell
    do shell script "echo 'Kindleアプリをアクティブ化しました' >> " & logFile
end if

-- アプリが起動するまで待機
delay 5
do shell script "echo '初期待機完了（5秒）' >> " & logFile

repeat with i from spage to pages
    do shell script "echo '--- ページ " & i & " 処理開始 ---' >> " & logFile
    
    -- Kindleアプリを確実にアクティブにする
    tell application target
        activate
    end tell
    do shell script "echo 'ページ " & i & ": Kindleアプリを再アクティブ化' >> " & logFile
    
    -- アプリがアクティブになるまで待機
    delay 1
    
    -- アプリの状態を確認
    try
        tell application "System Events"
            set appRunning to exists (process target)
            do shell script "echo 'ページ " & i & ": Kindleプロセス存在確認 = " & appRunning & "' >> " & logFile
            
            if appRunning then
                set frontmostApp to name of first application process whose frontmost is true
                do shell script "echo 'ページ " & i & ": 現在のフロントアプリ = " & frontmostApp & "' >> " & logFile
                
                tell process target
                    set isFrontmost to frontmost
                    do shell script "echo 'ページ " & i & ": Kindleがフロント = " & isFrontmost & "' >> " & logFile
                end tell
            end if
        end tell
    on error errMsg
        do shell script "echo 'ページ " & i & ": アプリ状態確認エラー = " & errMsg & "' >> " & logFile
    end try
    
    -- ファイル番号を3桁に整形
    if i < 10 then
        set dp to "00" & i
    else if i < 100 then
        set dp to "0" & i
    else
        set dp to i as string
    end if
    
    set spath to (savepath & "p" & dp & ".png")
    
    -- スクリーンショットを撮影（画面全体）
    do shell script "screencapture -x " & spath
    do shell script "echo 'ページ " & i & ": スクリーンショット撮影完了 = " & spath & "' >> " & logFile
    
    -- 切り抜き処理
    if cropx is not 0 and cropy is not 0 then
        if resizew is not 0 then
            do shell script "sips -c " & cropy & " " & cropx & " --resampleWidth " & resizew & " " & spath & " --out " & spath
        else
            do shell script "sips -c " & cropy & " " & cropx & " " & spath & " --out " & spath
        end if
    end if
    
    -- Kindleアプリでページ送り（方向に応じて右矢印または左矢印キー）
    do shell script "echo 'ページ " & i & ": ページ送り開始（方向=" & pagedir & "）' >> " & logFile
    
    try
        tell application "System Events"
            tell process target
                -- 方向に応じてキーを選択（1=左矢印、2=右矢印）
                if pagedir is 1 then
                    -- 左矢印キー（key code 123）
                    key code 123
                    do shell script "echo 'ページ " & i & ": 左矢印キー送信完了' >> " & logFile
                else
                    -- 右矢印キー（key code 124）
                    key code 124
                    do shell script "echo 'ページ " & i & ": 右矢印キー送信完了' >> " & logFile
                end if
            end tell
        end tell
    on error errMsg
        do shell script "echo 'ページ " & i & ": ページ送りエラー = " & errMsg & "' >> " & logFile
    end try
    
    delay pausetime
end repeat

do shell script "echo '=== スクリプト完了 ===' >> " & logFile

-- 処理完了通知を表示
display dialog "Kindleスクリーンショット処理が完了しました！

処理ページ数: " & pages & "ページ
保存フォルダ: " & savepath & "
ログファイル: ~/Desktop/kindle_debug.log

スクリーンショットファイルを確認してください。" buttons {"OK"} default button "OK" with title "Kindleスクリーンショット完了" with icon note

activate