Function Get-Playlists {
    Import-Csv "Playlists.csv" -Delimiter "," | Foreach-Object -Parallel { 
        $Name = $_.Name
        $Url = $_.Url 
    
        New-Item -Path "Music/$Name" -ItemType "directory"

        $DownloadArchive = "Music/$Name/$Name.archive.log"
        $Output = "Music/$Name/$Name.output.log"
        yt-dlp $Url `
            --quiet `
            --verbose `
            --audio-quality 0 `
            --audio-format opus `
            --extract-audio `
            --continue `
            --force-ipv4 `
            --ignore-errors `
            --no-overwrites `
            --download-archive $DownloadArchive `
            --add-metadata `
            --parse-metadata "%(title)s:%(meta_title)s" `
            --parse-metadata "%(uploader)s:%(meta_artist)s" `
            --parse-metadata "%(view_count)s:%(meta_views)s" `
            --parse-metadata "%(average_rating)s:%(meta_rating)s" `
            --extract-audio `
            --check-formats `
            --retries 20 `
            --fragment-retries 20 `
            --concurrent-fragments 5 `
            --match-filter "!is_live & !live" `
            --output "Music/$Name/%(title)s.%(ext)s" `
            --throttled-rate 100K `
            --ffmpeg-location "C:\Apps\FFMPEG\bin\ffmpeg.exe" `
            2>&1 | Tee-Object $Output
    }
}

Get-Playlists