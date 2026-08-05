# AI Orchestrator

The AI Orchestrator acts as the central brain of the `falcon_ai_services` module. It accepts normalized requests from the AI Gateway and routes them through a modular decision-making pipeline.

## Pipeline Flow

1. **Gateway Interception**: `AIGateway` forwards the validated `GatewayRequest`.
2. **Context Builder**: The request is wrapped in an `OrchestratorContext`. In future phases, this stage will retrieve historical session data (memory).
3. **Intent Analysis**: The `IntentAnalyzer` examines the message and assigns an intent (e.g., `chat`, `coding`, `translation`).
4. **Dispatcher**: Based on the intent, the dispatcher selects the appropriate component to handle the request.
5. **Model Execution**: The selected model (currently `PlaceholderModel`) generates a response.
6. **Return**: The orchestrator returns a standard dictionary (reply, usage) back to the gateway.

## Components

- `OrchestratorContext`: The state object passed sequentially through the pipeline.
- `IntentAnalyzer`: Rule-based intent classifier. (Will be augmented with LLM intent recognition in later phases).
- `PlaceholderModel`: A deterministic test mock to ensure pipeline connectivity.

## Integration

The AI Orchestrator is completely decoupled from the AI Gateway. It operates strictly on the `GatewayRequest` object. The Gateway does not know *how* the Orchestrator fulfills the request, and the Orchestrator does not know *how* the Gateway validates the API payload.
