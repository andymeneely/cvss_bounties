import os

APP_ROOT_PATH = os.path.normpath(os.path.dirname(os.path.abspath(__file__)))

XMLS_DIRECTORY = os.path.join(APP_ROOT_PATH, 'data/xml')
NVD_XML_URL_TEMPLATE = 'https://nvd.nist.gov/feeds/xml/cve/{filename}'
NVD_GZXML_FILENAME_TEMPLATE = 'nvdcve-2.0-{year}.xml.gz'
NVD_XML_FILENAME_TEMPLATE = 'nvdcve-2.0-{year}.xml'
NVD_CVSS_XML_NAMESPACE = 'http://scap.nist.gov/schema/cvss-v2/0.2'
