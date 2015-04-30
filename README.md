# cts_check
The code in this repository is intended to assist Bridget Almas and the team at Perseus/Perseids to compare the tags of XML documents with the CTS URNs they create. The structure of Perseus XML is occasionally unpredictable and as a result, it cannot be parsed automatically. The supervised parsing of Perseus XML used in this code was developed by Chris Forstall for the Tesserae project at the University at Buffalo (http://www.tesserae.caset.buffalo.edu). See 'LICENSE.md' for more details.

# Usage:
'test.pl' will pull all CTS text URIs from Perseus, guide the user through parsing the associated XML document, and then check the XML tags against the CTS URI's for the text. 

Right now, the script tells you if:
a) the XML tags repeat at any point 
b) there are tags in the XML that don't correspond to CTS tags, and 
c) if there are  CTS URIs that have no antecedent among the XML tags.

The above information is printed directly to the terminal. A file is also generated which lets you know which CTS URIs are not associated with XML files (according to the results of a GetCapabilities request to the Perseus CTS server).

# Instructions:

To begin, run the PERL script test.pl from the terminal. Requires the installation of the following packages:

use Data::Dumper;
use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;
use File::Copy;
use Term::UI;
use Term::ReadLine;
use File::Fetch;
use XML::Simple;
use Term::UI;
use Term::ReadLine;
use XML::LibXML;
use Getopt::Long;
use Pod::Usage;
use Storable;

Code is in process of being documented. Please contact jamesgaw@buffalo.edu with any questions.