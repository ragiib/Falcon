# Windows Native Speech Recognition & Wake-Word Listener for Falcon AI
trap {
    [Console]::WriteLine("TRAP ERROR: $($_.Exception.Message)")
    Out-File -FilePath "c:\falcon\scripts\stt_error.log" -InputObject "TRAP ERROR: $($_.Exception.Message)" -Append
    exit 1
}
Add-Type -AssemblyName System.Speech

$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
try {
    $recognizer.SetInputToDefaultAudioDevice()
} catch {
    [Console]::WriteLine("ERROR: No default audio recording device found.")
    exit 1
}

# Create a free-dictation grammar for continuous speech recognition
$dictationGrammar = New-Object System.Speech.Recognition.DictationGrammar
$dictationGrammar.Name = "FalconDictation"
$recognizer.LoadGrammar($dictationGrammar)

# Also add explicit Wake-Word Grammar for high accuracy "Falcon" detection
$builder = New-Object System.Speech.Recognition.GrammarBuilder
$choices = New-Object System.Speech.Recognition.Choices
$choices.Add([string[]]@("Falcon", "Hey Falcon", "OK Falcon", "Computer"))
$builder.Append($choices)
$wakeGrammar = New-Object System.Speech.Recognition.Grammar($builder)
$wakeGrammar.Name = "WakeWordGrammar"
$recognizer.LoadGrammar($wakeGrammar)

# Event Handlers safely marshalled to main thread
Register-ObjectEvent -InputObject $recognizer -EventName "SpeechRecognized" -Action {
    $e = $Event.SourceEventArgs
    if ($e.Result.Text) {
        $text = $e.Result.Text.Trim()
        if ($text.Length -gt 0) {
            # Exact wake-word match triggers wake activation; any other spoken phrase is passed as recognized dictation text
            if ($text -ieq "Falcon" -or $text -ieq "Hey Falcon" -or $text -ieq "OK Falcon" -or $text -ieq "Computer") {
                [Console]::WriteLine("WAKE_WORD_DETECTED")
            } else {
                [Console]::WriteLine("RECOGNIZED:$text")
            }
        }
    }
} | Out-Null

Register-ObjectEvent -InputObject $recognizer -EventName "AudioLevelUpdated" -Action {
    $e = $Event.SourceEventArgs
    # Output live audio volume (0-100) for visualizer pulse
    [Console]::WriteLine("VOLUME:$($e.AudioLevel)")
} | Out-Null

[Console]::WriteLine("STT_INITIALIZED")
try {
    $recognizer.RecognizeAsync([System.Speech.Recognition.RecognizeMode]::Multiple)
} catch {
    Write-Output "EXCEPTION: $_"
    exit 1
}

# Keep process alive and process events synchronously
while ($true) {
    Wait-Event -Timeout 1 | Out-Null
}
