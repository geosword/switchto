import unittest
from switchto import whichwmctrl
from switchto import wmctrl

class testSwitchToPY(unittest.TestCase):
	def test_whichwmctrl(self):
		self.assertIsNotNone(whichwmctrl)

	def test_wmctrl(self):
		wmctrl_stdout,wmctrl_stderr = wmctrl(['-d'])
		self.assertIsNotNone( wmctrl_stdout )

if __name__ == '__main__':
    unittest.main()
