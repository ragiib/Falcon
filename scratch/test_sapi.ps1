Add-Type -AssemblyName System.Speech
$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
try {
    $recognizer.SetInputToDefaultAudioDevice()
    Write-Host "SAPI initialized successfully with default audio device."
    $builder = New-Object System.Speech.Recognition.GrammarBuilder
    $choices = New-Object System.Speech.Recognition.Choices
    $choices.Add([string[]]@("Falcon wake up", "Falcon", "Hey Falcon wake up"))
    $builder.Append($choices)
    $wakeGrammar = New-Object System.Speech.Recognition.Grammar($builder)
    $recognizer.LoadGrammar($wakeGrammar)
    Write-Host "Grammar loaded successfully."
} catch {
    Write-Host "Error initializing SAPI: $_"
}
