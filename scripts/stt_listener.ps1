# Windows Native Speech Recognition & Wake-Word Listener for Falcon AI
Add-Type -AssemblyName System.Speech

$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
try {
    $recognizer.SetInputToDefaultAudioDevice()
} catch {
    Write-Host "ERROR: No default audio recording device found."
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

# Event Handlers
$recognizer.add_SpeechRecognized({
    param($sender, $e)
    if ($e.Result.Text -and $e.Result.Confidence -gt 0.3) {
        $text = $e.Result.Text.Trim()
        if ($text -match "Falcon" -or $text -match "Computer") {
            Write-Host "WAKE_WORD_DETECTED"
        } else {
            Write-Host "RECOGNIZED:$text"
        }
    }
})

$recognizer.add_AudioLevelUpdated({
    param($sender, $e)
    # Output live audio volume (0-100) for visualizer pulse
    Write-Host "VOLUME:$($e.AudioLevel)"
})

Write-Host "STT_INITIALIZED"
$recognizer.RecognizeAsync([System.Speech.Recognition.RecognizeMode]::Multiple)

# Keep process alive
while ($true) {
    Start-Sleep -Milliseconds 100
}
