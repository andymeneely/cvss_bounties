import unittest

from library import utilities


class UtilitiesTestCase(unittest.TestCase):
    def test_get_details_valid(self):
        # Arrange
        nvdxml = utilities.NvdXml()
        expected = {
                'score': '9.3',
                'access-vector': 'NETWORK',
                'access-complexity': 'MEDIUM',
                'authentication': 'NONE',
                'confidentiality-impact': 'COMPLETE',
                'integrity-impact': 'COMPLETE',
                'availability-impact': 'COMPLETE',
                'source': 'http://nvd.nist.gov',
                'generated-on-datetime': '2016-01-13T22:20:01.847-05:00'
            }

        # Act
        actual = nvdxml.get_details('CVE-2016-0002')

        # Assert
        self.assertDictEqual(expected, actual)

    def test_get_details_invalid(self):
        # Arrange
        nvdxml = utilities.NvdXml()

        # Act
        actual = nvdxml.get_details('CVE-2016-99999999')

        # Assert
        self.assertIsNone(actual)

    def test_get_details_exception(self):
        # Arrange
        nvdxml = utilities.NvdXml()

        # Assert
        self.assertRaises(Exception, nvdxml.get_details, 'CVE-201-9999')
