import unittest

import requests

from library import utilities


class NvdXmlTestCase(unittest.TestCase):
    def test_get_details_valid(self):
        # Arrange
        nvdxml = utilities.NvdXml()
        expected = {
                'score': '9.3',
                'impact-subscore': 10.0,
                'exploitability-subscore': 8.6,
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


class ReportTestCase(unittest.TestCase):
    def test_get_details(self):
        # Arrange
        report = requests.get(
                'https://hackerone.com/reports/103993.json'
            ).json()
        expected = {
                'product': 'Ruby',
                'cve_ids': ['CVE-2015-3900'],
                'bounty': 1500.00
            }

        # Act
        actual = utilities.Report.get_details(report)

        # Assert
        self.assertDictEqual(expected, actual)

    def test_get_details_6626(self):
        # Arrange
        report = requests.get(
                'https://hackerone.com/reports/6626.json'
            ).json()
        expected = {
                'product': 'OpenSSL',
                'cve_ids': ['CVE-2014-0160'],
                'bounty': 15000.00
            }

        # Act
        actual = utilities.Report.get_details(report)

        # Assert
        self.assertDictEqual(expected, actual)


class TestCase(unittest.TestCase):
    def test_get_year(self):
        # Arrange
        cve_id = 'CVE-2010-0000'
        expected = 2010

        # Act
        actual = utilities.get_year(cve_id)

        # Assert
        self.assertEqual(expected, actual)

        # Arrange
        cve_id = 'CVE-2010-00000'
        expected = 2010

        # Act
        actual = utilities.get_year(cve_id)

        # Assert
        self.assertEqual(expected, actual)

        # Arrange
        cve_id = 'CVE-201-0000'

        # Assert
        self.assertRaises(Exception, utilities.get_year, cve_id)
