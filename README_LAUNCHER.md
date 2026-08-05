# Falcon AI Development Launcher

The Falcon AI Development Launcher is a native Windows startup manager that fully automates your development workflow. Rather than manually opening terminals and starting backend/frontend processes, the launcher handles environment validation, auto-discovery, logging, and sequential startup.

## Features

1. **Auto-Discovery:** Automatically locates your FastAPI backend (`api/app.py`) and Flutter project (`pubspec.yaml`) no matter how your project is structured within the directory.
2. **Intelligent Startup:**
   - Validates Python and Flutter dependencies.
   - Starts the FastAPI backend in a visible development console.
   - Polls the `/api/v1/health` endpoint to ensure the backend is fully initialized.
   - Launches the Flutter Windows application (`flutter run -d windows`) only after health checks pass.
3. **Logging Infrastructure:** Output is automatically recorded in `logs/launcher/` (including launcher events, backend stdout/stderr, and Flutter stdout/stderr).
4. **Desktop Integration:** Double-click the "Falcon AI" shortcut on your Desktop or Start Menu to launch the app just like a native Windows executable.

## How to Use

1. **First-time Setup:**
   Run `setup_shortcuts.ps1` to generate the Desktop and Start Menu shortcuts.
2. **Launch:**
   Simply double-click the **Falcon AI** shortcut on your desktop.
3. **Development Mode:**
   The backend terminal will remain visible so you can monitor API requests, CUDA logs, exceptions, and token metrics.
   The Flutter app will launch and connect automatically.
4. **Shutdown:**
   Close the Flutter application window. The backend console will remain open (if you want to keep the API running while restarting Flutter), or you can close the backend console to shut it down completely. 

## Troubleshooting

- **Python/Flutter not found:** Ensure both `python` and `flutter` are added to your system's `PATH` environment variable.
- **Port 8000 in use:** The launcher looks for `API_PORT` in your `.env` file. Change the port there if 8000 is occupied.
- **Backend crashes on startup:** Check the logs inside `logs/launcher/backend_*.log` or directly in the visible console window.

## Future Compatibility

The `FalconLauncher.ps1` script supports a `-Mode Release` flag. In the future, when Falcon is built into a production installer, the launcher can be updated to launch the pre-compiled `.exe` and start the backend invisibly.
