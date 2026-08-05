import unittest
from core.gateway.schemas import GatewayRequest
from core.orchestrator.schemas import OrchestratorContext
from core.orchestrator.intent_analyzer import IntentAnalyzer
from core.orchestrator.context_builder import ContextBuilder
from core.orchestrator.dispatcher import Dispatcher
from core.orchestrator.pipeline import OrchestratorPipeline
from core.orchestrator.orchestrator import AIOrchestrator

class TestAIOrchestrator(unittest.TestCase):
    def setUp(self):
        self.valid_request = GatewayRequest(
            request_id="req-123",
            session_id="sess-456",
            user_id="usr-789",
            message="Can you translate this to spanish?",
        )

    def test_intent_analyzer(self):
        context = OrchestratorContext(request=self.valid_request)
        context = IntentAnalyzer.analyze(context)
        self.assertEqual(context.intent, "translation")

    def test_context_builder(self):
        context = ContextBuilder.build(self.valid_request)
        self.assertEqual(context.request.request_id, "req-123")
        self.assertIn("session_id", context.session_info)

    def test_dispatcher(self):
        context = OrchestratorContext(request=self.valid_request, intent="chat")
        context = Dispatcher.dispatch(context)
        self.assertIsNotNone(context.model_response)
        self.assertIn("[CHAT]", context.model_response)

    def test_pipeline_execution(self):
        context = OrchestratorPipeline.execute(self.valid_request)
        self.assertEqual(context.intent, "translation")
        self.assertIn("[TRANSLATION]", context.model_response)

    def test_orchestrator_process(self):
        result = AIOrchestrator.process(self.valid_request)
        self.assertIn("reply", result)
        self.assertIn("usage", result)
        self.assertIn("[TRANSLATION]", result["reply"])

if __name__ == "__main__":
    unittest.main()
