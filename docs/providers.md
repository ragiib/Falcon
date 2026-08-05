# Model Provider Layer

The Provider Layer decouples the AI Orchestrator from the specific inference backends (e.g., local llama.cpp, OpenAI, vLLM). It defines a standard `IModelProvider` interface ensuring consistent operations across models.

## Architecture & Lazy Loading

The orchestration layer communicates only through `ProviderFactory.get_provider()`. 

The Model Provider utilizes **Lazy Loading**. The model is *not* loaded into memory when the application starts. Instead, it is loaded into memory only when the very first inference request is received by the orchestrator. After the initial request, the model is cached and reused for all subsequent requests to eliminate load times.

## Configuring Qwen (Local GGUF)

1. Download the Qwen 2.5 14B Q4_K_M model in `.gguf` format from HuggingFace.
2. Place the file anywhere on your disk (outside the source code repository).
3. Set your `.env` configuration:

```env
MODEL_PROVIDER=qwen
MODEL_PATH=/absolute/path/to/models/Qwen2.5-14B-Q4_K_M.gguf
MODEL_TEMPERATURE=0.7
```

## Verification Scripts

To ensure your model is correctly downloaded and configured without running the full application stack, use the provided development scripts:

- Standard Generation: `python dev/verify_qwen.py`
- Streaming Generation: `python dev/verify_qwen_stream.py`

These scripts will print execution time and tokens per second (TPS).

## Adding New Providers

1. Create a class implementing `IModelProvider` in `core/providers/`.
2. Implement `load_model()`, `unload_model()`, `generate()`, `generate_stream()`, and `health_check()`.
3. Ensure `generate()` and `generate_stream()` implement lazy loading by calling `self.load_model()` if the model is not yet loaded.
4. Register the class in `ProviderFactory.initialize()`.
