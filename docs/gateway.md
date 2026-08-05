# AI Gateway

The AI Gateway serves as the single public entry point to the entire AI system. It receives requests, validates and normalizes them, and routes them to the AI orchestrator. It returns a standardized response structure.

## Request Flow

1. **Client Request**: The external service (e.g., backend API) sends a raw dictionary payload to `AIGateway.process_request()`.
2. **Middleware**: The request passes through logging middleware, which tracks execution time and initiates an audit trail.
3. **Validation**: The raw payload is parsed and strictly validated by the `RequestValidator`.
4. **Orchestration**: If valid, the gateway forwards the extracted `GatewayRequest` object to the AI orchestrator (currently a placeholder).
5. **Response Wrapping**: The orchestrator's output is wrapped into a standardized `GatewayResponse` and returned.

## Schemas

### Standard Request Schema

| Field | Type | Required | Description |
|---|---|---|---|
| `request_id` | str | Yes | Unique identifier for the request |
| `session_id` | str | Yes | Conversation or session tracking ID |
| `user_id` | str | Yes | User identifier |
| `message` | str | Yes | The user's input message |
| `attachments` | list[dict] | No | File attachments. Supported formats: pdf, txt, image/png, image/jpeg |
| `metadata` | dict | No | Extensible metadata dictionary |
| `timestamp` | datetime | Auto | Datetime of the request creation |

### Standard Response Schema

| Field | Type | Description |
|---|---|---|
| `status` | str | "success" or "error" |
| `request_id` | str | The ID of the original request |
| `reply` | str (optional) | The AI's generated response text |
| `actions` | list[dict] | Programmatic actions the client should take |
| `metadata` | dict | Additional context |
| `usage` | dict | Token or resource usage statistics |
| `errors` | list[str] | List of validation or processing error messages |

## Error Codes & Handling

The gateway encapsulates all internal exceptions. If an internal failure or validation error occurs, it returns a standard response with `status: "error"` and the `errors` list populated with safe-to-display error messages.

* **GatewayValidationError**: Raised when required fields are missing, empty, or incorrectly typed.
* **Internal Processing**: Captured safely without exposing stack traces to the caller.
