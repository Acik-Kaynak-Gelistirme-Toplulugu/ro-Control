import unittest
from src.core.detector import SystemDetector
from unittest.mock import MagicMock

class TestSystemDetector(unittest.TestCase):
    def setUp(self):
        self.detector = SystemDetector()
        # Runner'ı mockla
        self.detector.runner = MagicMock()

    def test_gpu_detection_nvidia(self):
        # Mock çıktı (lspci -vmm)
        mock_output = """Slot:	01:00.0
Class:	VGA compatible controller
Vendor:	NVIDIA Corporation
Device:	GeForce RTX 4060
SVendor:	ASUSTeK Computer Inc.
SDevice:	Device 88b8
Rev:	a1
"""
        self.detector.runner.run.return_value = mock_output
        self.detector._detect_gpu_advanced()
        
        self.assertEqual(self.detector.gpu_info["vendor"], "NVIDIA")
        self.assertEqual(self.detector.gpu_info["model"], "GeForce RTX 4060")

    def test_gpu_detection_amd(self):
        mock_output = """Slot:	03:00.0
Class:	VGA compatible controller
Vendor:	Advanced Micro Devices, Inc. [AMD/ATI]
Device:	Navi 21 [Radeon RX 6800/6800 XT / 6900 XT]
"""
        self.detector.runner.run.return_value = mock_output
        self.detector._detect_gpu_advanced()
        
        self.assertEqual(self.detector.gpu_info["vendor"], "AMD")
        self.assertIn("Radeon RX 6800", self.detector.gpu_info["model"])

if __name__ == '__main__':
    unittest.main()
