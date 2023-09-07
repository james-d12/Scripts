[CmdletBinding()]
Param (
    [Parameter(
        Mandatory = $true, 
        ValueFromPipeline = $true, 
        ValueFromPipelineByPropertyName = $true, 
        HelpMessage = "The csv file containing the list of playlists to download.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
            if ($_ -notmatch '\.csv$') {
                throw "The Playlist File must end with '.csv'"
            }
            if (-not (Test-Path -Path $_ -PathType Leaf)) {
                throw "The specified path does not exist."
            }
            $true
        })]
    [String]$PlaylistFile,

    [Parameter(
        Mandatory = $true, 
        ValueFromPipeline = $true, 
        ValueFromPipelineByPropertyName = $true, 
        HelpMessage = "The output directory to store files to.")]
    [String]$OutputFolder,

    [Parameter(
        Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "The file type to download as."
    )]
    [ValidateSet("aac", "alac", "flac", "m4a", "mp3", "opus", "vorbis", "wav")]
    [String]$FileType
)

Begin {
    Write-Host -ForegroundColor Green "Beginning download of files. $PlaylistFile $FileType"

    if (-not (Test-Path -Path $OutputFolder)) {
        Write-Host -ForegroundColor Yellow "Creating new output directory $OutputFolder."
        New-Item -Path $OutputFolder -ItemType Directory
    }
}

Process {
    $PlaylistData = Import-Csv $PlaylistFile -Delimiter ","
    foreach ($Playlist in $PlaylistData) {
        $Name = $Playlist.Name
        $Url = $Playlist.Url 

        $MusicDirectory = "$OutputFolder/$Name"   
        $MusicArchiveLog = "$MusicDirectory/$Name.archive.log"
        $MusicOutputLog = "$MusicDirectory/$Name.output.log"
    
        New-Item -Path $MusicDirectory -ItemType Directory

        yt-dlp $Url `
            --quiet `
            --verbose `
            --audio-quality 0 `
            --audio-format $FileType `
            --extract-audio `
            --continue `
            --force-ipv4 `
            --ignore-errors `
            --no-overwrites `
            --download-archive $MusicArchiveLog `
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
            --output "$MusicDirectory/%(title)s.%(ext)s" `
            --throttled-rate 100K `
            --ffmpeg-location ".\ffmpeg.exe" `
            2>&1 | Tee-Object $MusicOutputLog
    }
}

End {
    Write-Host -ForegroundColor Green "Download of files has finished."
}
