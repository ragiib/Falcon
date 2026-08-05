import unittest
from core.providers import ProviderFactory
from config import settings

class TestProviders(unittest.TestCase):
    def setUp(self):
        # Force the factory to use placeholder for testing without loading real models
        settings.MODEL_PROVIDER = "placeholder"
        ProviderFactory._instance = None
        ProviderFactory.initialize()
        self.provider = ProviderFactory.get_provider()

    def test_lazy_loading(self):
        # Ensure model is not loaded initially
        self.assertFalse(self.provider.health_check()["model_loaded"])
        
        # Calling generate should trigger load_model
        response = self.provider.generate("Test prompt", intent="chat")
        
        self.assertTrue(self.provider.health_check()["model_loaded"])
        self.assertIn("Test prompt", response["reply"])
        self.assertIn("[CHAT]", response["reply"])
        self.assertIn("tokens", response["usage"])

    def test_health_check_format(self):
        health = self.provider.health_check()
        self.assertIn("provider", health)
        self.assertIn("model_loaded", health)
        self.assertIn("model_path", health)
        self.assertIn("inference_backend", health)
        self.assertIn("status", health)

    def test_unload_model(self):
        self.provider.load_model()
        self.assertTrue(self.provider.health_check()["model_loaded"])
        
        self.provider.unload_model()
        self.assertFalse(self.provider.health_check()["model_loaded"])

if __name__ == "__main__":
    unittest.main()
