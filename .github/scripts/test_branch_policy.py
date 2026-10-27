import unittest
from branch_policy import permitted

class BranchPolicyTests(unittest.TestCase):
    def test_promotions_and_direct_bypass(self):
        self.assertTrue(permitted('pull_request', 'release', 'develop'))
        self.assertTrue(permitted('pull_request', 'master', 'release'))
        for base, head in [('master', 'develop'), ('master', 'feature/x'), ('release', 'master')]:
            self.assertFalse(permitted('pull_request', base, head))

    def test_forks_cannot_impersonate_release(self):
        self.assertFalse(permitted('pull_request', 'master', 'release', False))
        self.assertFalse(permitted('pull_request', 'release', 'develop', False))
        self.assertTrue(permitted('push', '', 'develop'))
