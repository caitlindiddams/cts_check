# cts_check
The code in this repository is intended to assist Bridget Almas and the team at Perseus/Perseids to compare the tags of XML documents with the CTS URNs they create. The structure of Perseus XML is occasionally unpredictable and as a result, it cannot be parsed automatically. The supervised parsing of Perseus XML used in this code was developed by Chris Forstall for the Tesserae project at the University at Buffalo (http://www.tesserae.caset.buffalo.edu). See 'LICENSE.md' for more details.

#xml-structure and greek-xml-structure
These scripts are abbreviated versions of test.pl, including all of the important XML-parsing features but excluding all of the CTS-checking features. Useful if you want to strip all the XML out of Perseus texts but don't want to lose the line or book numbers.

# Usage:
'test.pl' will pull all CTS text URIs from Perseus, guide the user through parsing the associated XML document, and then check the XML tags against the CTS URIs for the text. 

Right now, the script tells you if:
1. the XML tags repeat at any point 
2. there are tags in the XML that don't correspond to CTS tags, and 
3. if there are  CTS URIs that have no antecedent among the XML tags.

The above information is printed directly to the terminal. A file is also generated which lets you know which CTS URIs are not associated with XML files (according to the results of a GetCapabilities request to the Perseus CTS server).

# Instructions:

To begin, run the PERL script test.pl from the terminal. Requires the installation of the following packages:

* Data::Dumper;
* Cwd qw/abs_path/;
* File::Spec::Functions;
* FindBin qw/$Bin/;
* File::Copy;
* Term::UI;
* Term::ReadLine;
* File::Fetch;
* XML::Simple;
* Term::UI;
* Term::ReadLine;
* XML::LibXML;
* Getopt::Long;
* Pod::Usage;
* Storable;

Code is in process of being documented. Please contact jamesgaw@buffalo.edu with any questions.