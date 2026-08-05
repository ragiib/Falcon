import unittest
from core.gateway.gateway import AIGateway

class TestAIGateway(unittest.TestCase):
    def setUp(self):
        self.gateway = AIGateway()
        self.valid_request = {
            "request_id": "req-123",
            "session_id": "sess-456",
            "user_id": "usr-789",
            "message": "Hello AI"
        }

    def test_valid_request_successful_response(self):
        response = self.gateway.process_request(self.valid_request)
        self.assertEqual(response["status"], "success")
        self.assertEqual(response["request_id"], "req-123")
        self.assertIn("[CHAT]", response["reply"])
        self.assertIn("Hello AI", response["reply"])
        self.assertEqual(len(response["errors"]), 0)

    def test_missing_required_field(self):
        invalid_req = {"session_id": "sess-456", "user_id": "usr-789", "message": "Hello"}
        response = self.gateway.process_request(invalid_req)
        self.assertEqual(response["status"], "error")
        self.assertIn("Missing required field: 'request_id'", response["errors"])

    def test_empty_message(self):
        invalid_req = self.valid_request.copy()
        invalid_req["message"] = "   "
        response = self.gateway.process_request(invalid_req)
        self.assertEqual(response["status"], "error")
        self.assertIn("Message cannot be empty", response["errors"])

    def test_invalid_schema_type(self):
        invalid_req = self.valid_request.copy()
        invalid_req["attachments"] = "not_a_list"
        response = self.gateway.process_request(invalid_req)
        self.assertEqual(response["status"], "error")
        self.assertIn("Field 'attachments' must be a list", response["errors"])

    def test_unsupported_attachment_format(self):
        invalid_req = self.valid_request.copy()
        invalid_req["attachments"] = [{"format": "exe", "data": "..."}]
        response = self.gateway.process_request(invalid_req)
        self.assertEqual(response["status"], "error")
        self.assertIn("Unsupported attachment format: exe", response["errors"])

if __name__ == "__main__":
    unittest.main()
