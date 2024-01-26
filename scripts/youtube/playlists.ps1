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

try {

    Write-Host "📋 Checking if ffmpeg is installed..."
    
    $filteredResult = (winget list) | Where-Object { $_ -like "*ffmpeg*"}

    if ($filteredResult.Count -gt 0) {
        Write-Host "✔️ Found ffmpeg package."
    } else {
        Write-Host "❌ Could not find ffmpeg package, attempting to install."
        winget install -e --id Gyan.FFmpeg
        exit 1
    }

    Write-Host "📋 Checking if yt-dlp is installed..."
    
    $filteredResult = (winget list) | Where-Object { $_ -like "*yt-dlp*"}

    if ($filteredResult.Count -gt 0) {
        Write-Host "✔️ Found yt-dlp package."
    } else {
        Write-Host "❌ Could not find yt-dlp package, attempting to install."
        winget install -e --id yt-dlp.yt-dlp
        exit 1
    }

    Write-Host -ForegroundColor Green "Beginning download of files. $PlaylistFile $FileType"
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
            --progress `
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
            #--ffmpeg-location ".\ffmpeg.exe" `
            2>&1 | Tee-Object $MusicOutputLog
    }
    
    Write-Host -ForegroundColor Green "Download of files has finished."
} catch {
    Write-Host "An error occurred whilst trying to download playlists: $_"
    exit 1
}