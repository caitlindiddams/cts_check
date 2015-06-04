#!/usr/bin/env perl

#
# This is a template for how Tesserae scripts should begin.
#
# Please fill in documentation notes in POD below.
#
# Don't forget to modify the COPYRIGHT section as follows:
#  - name of the script where it says "The Original Code is"
#  - your name(s) where it says "Contributors"
#

=head1 NAME

test.pl - designed to test Perseus CTS servers, retrieve all text URIs and associated XML files, parse the XML files, and check the resulting 
XML tags against the CTS tags returned by a GetValidReffs query. 

=head1 SYNOPSIS

name.pl [options] ARG1 [, ARG2, ...]

=head1 DESCRIPTION

A more complete description of what this script does.

=head1 OPTIONS AND ARGUMENTS

=over

=item I<ARG1>

Description of what ARG1 does.

=item B<--option>

Description of what --option does.

=item B<--help>

Print usage and exit.

=back

=head1 KNOWN BUGS

=head1 SEE ALSO

=head1 COPYRIGHT

University at Buffalo Public License Version 1.0.
The contents of this file are subject to the University at Buffalo Public License Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://tesserae.caset.buffalo.edu/license.txt.

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific language governing rights and limitations under the License.

The Original Code is test.pl.

The Initial Developer of the Original Code is Research Foundation of State University of New York, on behalf of University at Buffalo.

Portions created by the Initial Developer are Copyright (C) 2007 Research Foundation of State University of New York, on behalf of University at Buffalo. All Rights Reserved.

Contributor(s): Chris Forstall, James Gawley

Alternatively, the contents of this file may be used under the terms of either the GNU General Public License Version 2 (the "GPL"), or the GNU Lesser General Public License Version 2.1 (the "LGPL"), in which case the provisions of the GPL or the LGPL are applicable instead of those above. If you wish to allow use of your version of this file only under the terms of either the GPL or the LGPL, and not to allow others to use your version of this file under the terms of the UBPL, indicate your decision by deleting the provisions above and replace them with the notice and other provisions required by the GPL or the LGPL. If you do not delete the provisions above, a recipient may use your version of this file under the terms of any one of the UBPL, the GPL or the LGPL.

=cut

use strict;
use warnings;
use Data::Dumper;
#
# Read configuration file
#

# modules necessary to read config file

use Cwd qw/abs_path/;
use File::Spec::Functions;
use FindBin qw/$Bin/;
use File::Copy;
use Term::UI;
use Term::ReadLine;
use File::Fetch;
use XML::Simple;
use utf8;
use Term::UI;
use Term::ReadLine;

use XML::LibXML;
# read config before executing anything else
binmode STDOUT, ":utf8";

#
# set up terminal interface
#

my $term = Term::ReadLine->new('myterm');





#
# The code below is left-over from this programs origins as an extension of the Tesserae system. It hasn't been removed because the code in this script will 
# (hopefully) one day facilitate direct communication between Perseus CTS servers and the Tesserae search server.
#


# load Tesserae-specific modules
#use Tesserae;
use TessCTS;
use EasyProgressBar;

# modules to read cmd-line options and print usage

use Getopt::Long;
use Pod::Usage;

# load additional modules necessary for this script

use Storable;

# initialize some variables
my $spacer = "\n*******************************************************************************\n";
my $quiet = 0;
my $help = 0;

# get user options

GetOptions(
	'help'  => \$help,
   'quiet' => \$quiet
);

# print usage if the user needs help	

if ($help) {
	pod2usage(1);
}



#my $urn = "urn:cts:latinLit:phi0917.phi001.perseus-lat1"; # this initial variable can be used with Chris' 'verify' subroutine below.
			
#print TessCTS::cts_get_passage("$urn:1.425") . "\n";


# First we need the URNs of all CTS documents available to the server.
print "Getting file list...";
my $cap = TessCTS::cts_request("http://www.perseus.tufts.edu/hopper/CTS", "GetCapabilities");
my $refs;
my $xml = new XML::Simple;
$refs = $xml->XMLin($cap);
my @missing_xml;
open (OUT, ">tmp/output.txt"), or die $!;
open (MISS, ">tmp/missing.txt"), or die $!;
open (LIST, ">tmp/files.txt"), or die $!;
print OUT Dumper $refs;	

my @xml_files;
my @cts_uris;
#
# Retrieve all CTS URIs from the Perseus CTS server, and associate them with XML files.
#

# Using XML::Simple means that each possible branching of CTS tags has to be accounted for. This is inferior to the system used in the parseXML subroutine,
# and should probably be changed. The reliability of CTS tagging is the only reason the current system works at all.
# CTS URNs returned by the GetCapabilities usually contain the filename of the corresponding XML file, like this: textinventory->textgroup->work->online->docname


# Sometimes the 'work' tag repeats in the same textgroup, and is therefore treated by XML::Simple as an array. Sometimes the 'edition' field repeats within the same work, and is treated as an array.
# Hence there are four possible tag arrangements.
foreach my $textgroup (@{$refs->{'textgroup'}}) {
	if (ref($textgroup->{'work'}) eq 'ARRAY'){ #if there's more than one work...
		foreach my $work (@{$textgroup->{'work'}}) {
			my $u = $work->{'urn'};
			if (ref($work->{'edition'}) eq 'ARRAY') { #here there is more than one edition of the work...
				foreach my $edition (@{$work->{'edition'}}) {
				my $d = $edition->{'online'}->{'docname'};
					if ($d) {
						print LIST "\nURN: " . $u . "\t XML: " . $d; #Record all CTS URNS with their corresponding XML filenames.
						push (@xml_files, $d); #These arrays are only built if the both CTS and XML exist.
						push (@cts_uris, $u);
					}
					else {
						push (@missing_xml, $u); #Note any CTS URNS without corresponding XML file IDs
					}
				}
			}
			else { 
				my $d = $work->{'edition'}->{'online'}->{'docname'};			
				if ($d) {
					print LIST "\nURN: " . $u . "\t XML: " . $d;
						push (@xml_files, $d);
						push (@cts_uris, $u);
				}
				else {
					push (@missing_xml, $u);
				}
			}
		}
	}
	else {
		#The 'work' tag only exists once in this group
		my $u = $textgroup->{'work'}->{'urn'};
			if (ref($textgroup->{'work'}->{'edition'}) eq 'ARRAY') { #Just one there's only one work in the group, but more than one edition of the work...
				foreach my $edition (@{$textgroup->{'work'}->{'edition'}}) {
					my $d = $edition->{'online'}->{'docname'};
						if ($d) {
							print LIST "\nURN: " . $u . "\t XML: " . $d;
						push (@xml_files, $d);
						push (@cts_uris, $u);
						}
						else {
							push (@missing_xml, $u);
						}
					}
			}
			else { 
				my $d = $textgroup->{'work'}->{'edition'}->{'online'}->{'docname'};			
				if ($d) {
					print LIST "\nURN: " . $u . "\t XML: " . $d;
						push (@xml_files, $d);
						push (@cts_uris, $u);
				}
				else {
					push (@missing_xml, $u);
				}
			}
	}

}
my %cts_index;
my %xml_index;

for my $array_address (0..$#cts_uris) { #Make an index of cts_uris array addresses, keyed by URI so that users can select the text that way.
	$cts_index{$cts_uris[$array_address]} = $array_address; #Now you can use URI as the key and you'll get that URI's location in the array as a value.
	$xml_index{$xml_files[$array_address]} = $array_address;
}



print MISS "URIs which appear to be missing XML file tags: \n" . join ("\n", @missing_xml);
print "\n" . scalar (@cts_uris) . " CTS URIs identified. " . scalar (@missing_xml) . " URIs could not be associated with XML files.";



my $text_choice = '';
my $p = -1;
until($text_choice eq 'Quit') {
print "$spacer Ready to parse XML files. Files will be converted to .tess format, then reloaded for comparison with CTS files";
$text_choice = $term->get_reply(
	prompt  => 'Which action would you like to take?',
	default => 'Next',
	choices  => ['Specific CTS URI', 'Specific XML Doc', 'Previous', 'Repeat Current', 'Next', 'Quit']
	);

if ($text_choice eq 'Quit') { next;}

#If the user isn't quiting, select a new text.
if ($text_choice eq 'Next') {
	$p++;
}
if ($text_choice eq 'Previous') {
	if ($p < 1) {
		print "You can go backwards yet; you've haven't processed two texts yet";
		next;
	}
	$p--;
}
if ($text_choice eq 'Specific CTS URI') {
	my $key = $term->get_reply(
		prompt => "Enter a text URI. Example: $cts_uris[1]",
		default => $cts_uris[1]
	);
	#exchange the key for the array address
	$p = $cts_index{$key};
}

if ($text_choice eq 'Specific XML file') {
	my $key = $term->get_reply(
		prompt => "Enter an XML filename. Example: $xml_files[1]",
		default => $xml_files[1]
	);
	#exchange the key for the array address
	$p = $xml_index{$key};
}


print "Comparing $cts_uris[$p] with $xml_files[$p]... \nStep one: retrieving the XML file: http://www.perseus.tufts.edu/hopper/dltext?doc=Perseus%3Atext%3A$xml_files[$p]\n";
$xml_files[$p] =~ s/\.xml$//;
my $ff = File::Fetch->new(	uri => "http://www.perseus.tufts.edu/hopper/dltext?doc=Perseus%3Atext%3A$xml_files[$p]",
							scheme => "http",
							host => "http://www.perseus.tufts.edu",
							path => "/hopper/dltext?doc=Perseus%3Atext%3A$xml_files[$p]",
							output_file => "Perseus_text_$xml_files[$p].xml"
						);
my $contents;
my $where = $ff->fetch( to => 'tmp' );
#	copy ($where, "tmp/Perseus_text_$xml_files[$p].xml");
print "\nStep two: parsing the XML...\n";
my $tessfile = parseXML($where);
print "Verifying file: $tessfile\n";
verifyXML($tessfile, $cts_uris[$p]);


}

#verify("lucan.bellum_civile", $urn);

#
# 
#

sub verifyXML {
   my ($text_id, $urn) = @_;
   


   	open (X, "<:utf8", $text_id) or die $!;
   	my @tess_line;
	my %index_tess;
	my $count = 0;
	my $sample = '';
	my $flag = 0;
	while (<X>) {
		if ($count < 5) {
			$sample .= $_;
			$count++;
		}
		$_ =~ /^<\D+([A-Za-z0-9]+\.?[A-Za-z0-9]*\.?[A-Za-z0-9]*)>/;
		my $tag = $1;
		
		if (exists ($index_tess{$tag})) {
			print "XML tag repeats: $tag\n";
			$flag++;
		}
		$index_tess{$tag} = 1;
		push (@tess_line, $_);
	}
	print "Sample:\n$sample\n";
	if ($flag == 0) {
		print "No repeats detected in XML tags.\n";
	}
	my $cap = TessCTS::cts_request("http://www.perseus.tufts.edu/hopper/CTS", "GetValidReff", {urn => $urn});
	if ($cap) {
	my $xml = new XML::Simple;
	$refs = $xml->XMLin($cap);
	my $urn_ref = $refs->{'reply'}->{'reff'}->{'urn'};
	if (ref($urn_ref) eq 'ARRAY') {
		my @urns = @{$urn_ref};
		#Are there as many XML tags as CTS tags?
		
		if (scalar(keys %index_tess) == scalar (@urns)) {
			print "The number of CTS URNS and XML tags is equal.";
		}
		else {
			print "There are " . scalar(keys %index_tess) . "XML tags but " . scalar (@urns) . "CTS URNs.\n";
		}
		my %index_cts;
		for my $p (0..$#urns) {
			$urns[$p] =~ s/\Q$urn//;
			$urns[$p] =~ s/.+\://;
			if (exists $index_cts{$urns[$p]}) {
				print "CTS URN repeats: $urns[$p]";
			}
			$index_cts{$urns[$p]} = 1;
		}
		my $newflag = 0;
		foreach my $tag (keys %index_cts) {
			if (exists($index_tess{$tag})) {
				next;
			}
			else {
				print "The following location appears in the CTS but not the XML: $tag\n";
				$newflag++;
			}
		}
		foreach my $tag (keys %index_tess) {
			if (exists($index_cts{$tag})) {
				next;
			}
			else {
				print "The following location appears in the XML but not the CTS: $tag\n";
				$newflag++;
			}
		}		
		if ($newflag == 0) {
			print "There are no apparent discrepancies between XML tags and CTS URNS.";
		}
	}
	else {
		print "URN tags either don't exist, or there is only one. Hash of TEI elements is as follows:\n";
		print Dumper $refs;
	}
}
else {
	print "The CTS server did not respond to the request for file: $urn\n"
}
			my $useless = <STDIN>;
   
   
      	
}





sub parseXML { #this sub used to be an independent perl script for parsing XML files and switching them to .tess format.
#it still does this, and now returns the name of the .tess file created. This name can in turn be fed to 'validate'.

	my $file = shift;
	my $filename;
	#
	# step 1: parse the file
	#
	
	# create a new parser object
		
	my $parser = XML::LibXML->new();
	
	# open the file
	
	open (my $fh, "<", $file)	|| die "can't open $file: $!";

	# this line is where the whole file is read 
	# and turned into an XML::LibXML object.
	# from now on we're done with the original
	# file and we'll work with $doc
	#
	# unfortunately, i think this will only work if you
	# have internet access, because the documents use
	# a remote DTD for validation

	my $doc = $parser->parse_fh( $fh );

	# close the file

	close ($fh);
	
	print STDERR "\n";
	
	my @title = $doc->findnodes("/TEI.2/teiHeader/fileDesc/titleStmt/title");
	
	for (@title) {
	
		$_ = $_->textContent;
		
		next unless $_;
	
		print STDERR "\t$_\n";
	}
	
	print STDERR "\n";
	
	#
	# step 2: the parsing is done, now we can search
	#         the structure of the xml document
	#
	
	my @struct = @{getStruct($doc)};
	
	#
	# step 3: get all the texts in this doc
	#
	
	my @text = $doc->findnodes("//text[not(text)]");
		
	#
	# process each text
	#
	
	for my $t (0..$#text) {

		my $text = $text[$t];

		#
		# identify the text
		#
		
		print STDERR "\n";

		print STDERR "text $file.$t.\t";
		
		my @a = $text->findnodes("attribute::*");
		
		for (@a) {
		
			$_ = $_->nodeName . "=" . $_->nodeValue;
		}
		
		print STDERR join(" ", @a) . "\n\n";
		
		my $text_name = $term->get_reply(
			prompt  => 'Enter an abbreviation for this text?',
			default => 'auth. work.');
		
		#
		# Use one of the structures found in the header to guess which
		# TEI elements denote structural elements.
		#
				
		print STDERR "\n\n";
		
		print STDERR "Looking for predefined structure to start from.\n";
		print STDERR "You can edit this structure by hand later.\n";
		
		my $presumed = $term->get_reply(
				prompt   => 'Your choice?',
				choices  => [ uniq(@struct), 'none of these' ],
				print_me => 'Available structures:',
				default  => (defined $struct[$t] ? $struct[$t] : 'none of these'));
				
		# @div holds structural units
		
		my @div;
		
		if ($presumed ne 'none of these') { 

			my @names = split('\.', $presumed);
			
			for (@names) { 
			
				push @div, {name => $_, elem => '?'}
			}
		}
				
		#
		# count all TEI elements in this <text>
		#
		
		my %count;
		
		for my $elem ($text->findnodes("descendant::*")) {
		
			my $name = $elem->nodeName;
			
			# for divn and milestone nodes,
			# note the type/unit attribute,
			# since they may occur at multiple
			# hierarchical levels
			
			if ($name =~ /div/) {
			
				$name .= "[type=" . $elem->getAttribute("type") . "]";
			}
			
			if ($name eq 'milestone') {
			
				$name .= "[unit=" . $elem->getAttribute("unit") . "]";
			}
		
			$count{$name}++;
		}
		
		#
		# now we have a list of all the different
		# kinds of elements that occur.
		#
		# do two guessing tasks:
		# (1) guess which are to be assigned to structural units
		# (2) guess which are to be deleted
		#
		
		my @omit_candidates = qw/note head gap/;

		# how much space to allow in the table

		my $maxname = 0;
		my $maxcount = 0;

		# %omit holds elements to be removed before parsing
		
		my %omit;		
		
		# look at all the elements in turn

		for my $elem (keys %count) {
		
			# adjust the length
		
			$maxname  = length($elem) if length($elem) > $maxname;
			$maxcount = length($count{$elem}) if length($count{$elem}) > $maxcount;
			
			# test whether they match a structural unit's name
			
			for my $i (0..$#div) {
			
				my $name = $div[$i]{name};
			
				if (($elem =~ /$name/i) or
					(lc($name) eq 'line' and $elem eq 'l') or
					(lc($name) eq 'line' and $elem eq 'lb')) {
				
					$div[$i]{elem} = $elem;
				}
			}
			
			# test whether they match deletion candidates
			
			$omit{$elem} = (grep { /^$elem$/i } @omit_candidates) ? 1 : 0;			
		}
		
		#
		# assign structural units to elements
		#
		
		print STDERR "\n\n";
			
		print STDERR "these are all the TEI elements in your text:\n";
		
		my @elem = (sort keys %count);
	
		print STDERR sprintf("\t%-${maxcount}s %-${maxname}s\n", "count", "name");
	
		for (@elem) {
		
			print STDERR sprintf("\t%-${maxcount}s %-${maxname}s\n", $count{$_}, $_);
		}
		
		print STDERR "\n\n";
		
		print STDERR "here we will assign TEI elements to units of text structure.\n";
				
		while (1) {
		
			my $message = "Current assignment:\n";
		
			for my $i (0..$#div) {
						
				$message .= sprintf("\t%i. %s -> %s\n", $i+1, $div[$i]{name}, ($div[$i]{elem} || "?"));
			}
			
			$message .= "Your options:\n";
			
			my $default = 'finished';
			
			if ($#div < 0) { 
			
				$default = 'add a level';
			}
			else {
			
				for (@div) {
				
					if ($$_{elem} eq '?') {
						
						$default = 'change an assignment';
					}
				}
			}
			
			my $opt = $term->get_reply( 
				prompt   => 'Your choice?',
				choices  => ['change an assignment', 'add a level', 'delete a level', 'finished'],
				default  => $default,
				print_me => $message);
								
			if ($opt =~ /change/i) {

				@div = @{change_assignment(\@div, \@elem)};			
			}
			elsif ($opt =~ /add/i) {
				
				@div = @{add_level(\@div)};				
			}
			elsif ($opt =~ /delete/i) {

				@div = @{del_level(\@div)};
			}
			else {
				last;
			}
		}
		
		#
		# choose elements to omit
		#

		print STDERR "\n\n";

		my @omit = @{omit_dialog(\%omit, \@elem)};
				
		# delete them
				
		for my $elem_type (@omit) {
		
			my @nodes = $text->findnodes("descendant::$elem_type");
			
			next unless @nodes;
						
			for my $node (@nodes) {
			
				$node->unbindNode;
			}
		}
	
		#
		# name the output file
		# 

		print STDERR "\n\n";

		$filename = $term->get_reply(
			prompt  => 'Enter a name for the output file:',
			default => "tmp/currenttext.tess");

		$filename .= ".tess" unless ($filename =~ /\.tess$/);

		unless (open OFH, ">:utf8", $filename) {
		
			warn "Can't write to $filename.  Aborting this text.\n";
			next;
		}
						
		#
		# process the text
		#
		
		print STDERR "processing text\n";
		
		$text = $text->serialize;

		# delete all newlines, squash whitespace
		
		$text =~ s/\s+/ /sg;
		
		# transliterate greek
		
		$text =~ s/<foreign\s+lang="greek".*?>(.*?)<\/foreign>/beta_to_uni($1)/eg;
		$text =~ s/<quote\s+lang="greek".*?>(.*?)<\/quote>/beta_to_uni($1)/eg;

		# convert quote tags to quotation marks
		
		$text =~ s/<q\b.*?>/“/g;
		$text =~ s/<\/q>/”/g;
		
		# delete all closing tags
		
		$text =~ s/<\/.*?>//g;
		
		# change assigned unit tags to section boundary strings
		
		for my $i (0..$#div) {
		
			my $elem = $div[$i]{elem};
			my $name = $div[$i]{name};
		
			my $search;
		
			if ($elem =~ s/\[(.+)=(.+)\]//) {
			
				$search = "<$elem\\b([^>]*?$1\\s*=\\s*\"$2\"[^>]*?)\/?>"
			}
			else {
			
				$search = "<$elem\\b(.*?)>"
			}
			
			$text =~ s/$search/TESDIV$i--$1--/g;
		}
				
		# remove all remaining tags
		
		$text =~ s/<.*?>//g;
		
		# convert custom tags back into angle brackets
		
		$text =~ s/TESDIV(\d)--(.*?)--/<div$1 $2>/g;
		
		# break into chunks on units
		
		$text =~ s/</\n</g;
		
		my @chunk = split(/\n/, $text);
		
		# count chunks
		
		for (0..$#div) {
		
			$div[$_]{count} = 0;
		}
				
		for my $chunk (@chunk) {
		
			if ($chunk =~ s/^<div(\d)(.+?)>//) {
				
				my ($level, $attr) = ($1, $2);
				
				my $n;
				
				if ($attr =~ /\bn\s*=\s*"(.+?)"/) {
				
					$n = $1;
				}
				
				$div[$level]{count} = defined $n ? $n : incr($div[$level]{count});
				
				if ($level < $#div) {
				
					for ($level+1..$#div) {
					
						$div[$_]{count} = 0;
					}
				}
			}
			
			chomp $chunk;
			$chunk =~ s/^\s+//;
			$chunk =~ s/\s+$//;
			$chunk = beta_to_uni($chunk);			
			next unless $chunk =~ /\S/;
			
			my $tag = $text_name . " " . join(".", map {$$_{count}} @div);
			
			print OFH "<$tag> $chunk\n";
		}
		
		close OFH;
	}
 return $filename;
}
sub getStruct {

	my $doc = shift;

	# let's look for all unique paths from the document
	# root to its nodes.  this will give us some idea
	# of what kinds of structures exist in the document
	# and, if we count them, in what proportions
	
	my @struct;
	
	print STDERR "Reading document header\n";
	
	# look for <encodingDesc>
	
	my @enc = $doc->findnodes("//encodingDesc/refsDecl");
	
	for my $i (0..$#enc) {
			
		my $enc = $enc[$i];
			
		my @unit = $enc->findnodes("state");
		
		for (@unit) {
		
			$_ = $_->getAttribute("unit");
		}
		
		unless (@unit) {
		
			@unit = $enc->findnodes("step");
			
			for (@unit) {
			
				$_ = $_->getAttribute("refunit");
			}			
		}
		
		if (@unit) {
			
			push @struct, join(".", @unit);
		}
		
		$i++;
	}

	return \@struct;
}

sub uniq {

	my @array = @_;
		
	my %seen;
	
	my @return;
	
	for (@array) { 
	
		push (@return, $_) unless $seen{$_};

		$seen{$_} = 1;
	}
			
	return @return;
}

sub change_assignment {

	my ($divref, $elemref) = @_;
	
	my @div  = @$divref;
	my @elem = @$elemref;
	
	print STDERR "\n";
	
	if ($#div < 0) {
	
		print STDERR "Can't change assignment; no levels to assign.\n";
		return;
	}
	
	my $default = 1;
	
	for my $i (0..$#div) {
	
		if ($div[$i]{elem} eq '?') {
		
			$default = $i+1;
			last;
		}
	}
	
	my $menu = join("\n", map { "  $_> " . $div[$_-1]{name} } (1..$#div+1));
	
	my $fix = $term->get_reply(
		prompt   => "Your choice? ",
		print_me => "Change assignment for which division?\n\n" . $menu . "\n",
		allow    => [1..$#div+1],
		default  => $default);
				
	$fix--;
	
	print STDERR "\n";
		
	my $assign = $term->get_reply(
		prompt   => "Your choice? ",
		print_me => "Choose an element to assign to $div[$fix]{name}\n",
		choices  => [@elem],
		default  => $elem[0]);
		
	$div[$fix]{elem} = $assign;
	
	return \@div;
}

sub add_level {

	my $ref = shift;
	my @div = @$ref;
	
	print STDERR "\n";

	my $menu = join("\n", 
		(map { "  $_> before " . $div[$_-1]{name} } (1..$#div+1)),
		sprintf("  %i> at the end", $#div+2));
		
	my $add = $term->get_reply(
		prompt   => "Your choice? ",
		print_me => "Where do you want the new level?\n\n" . $menu . "\n",
		allow    => [1..$#div+2],
		default  => $#div+2);
				
	my $name = $term->get_reply(
		prompt  => "What is this level called? ",
		default => sprintf("level%i", $add-1));
				
	$add--;
					
	splice (@div, $add, $#div+1-$add, {name => $name, elem => "?"}, @div[$add..$#div]);
	
	return \@div;
}

sub del_level {

	my $ref = shift;
	my @div = @$ref;
	
	print STDERR "\n";

	my $menu = join("\n", 
	
		map { "  $_> " . $div[$_-1]{name} } (1..$#div+1));
		
	my $del = $term->get_reply(
		prompt   => "Your choice?",
		print_me => "Delete which level?\n\n" . $menu . "\n",
		allow    => [1..$#div+1],
		default  => "$#div");
				
	splice (@div, $del-1, 1);
	
	return \@div;
}

sub omit_dialog {

	my ($omitref, $elemref) = @_;
	my %omit = %$omitref;
	my @elem = @$elemref;
	
	DIALOG: while (1) {

		my $message = "Toggle TEI elements to omit:\n"
					. " starred elements will not be parsed.\n";

		my @choice = $term->get_reply(
			prompt   => "Your choice? ",
			choices  => [(map { ($omit{$_} ? "*" : " ") . $_} @elem ), "finished."],
			default  => "finished.",
			multi    => 1,
			print_me => $message);
			
		for my $choice (@choice) {
	
			last DIALOG if $choice eq "finished.";
	
			substr($choice, 0, 1, "");
				
			$omit{$choice} = ! $omit{$choice};		
		}
	}
	
	my @omit = grep { $omit{$_} } keys %omit;
	
	return \@omit;
}

sub beta_to_uni {
	
	my @text = @_;
	
	for (@text)	{
		
		s/(\*)([^a-z ]+)/$2$1/g;
		
		s/\)/\x{0313}/ig;
		s/\(/\x{0314}/ig;
		s/\//\x{0301}/ig;
		s/\=/\x{0342}/ig;
		s/\\/\x{0300}/ig;
		s/\+/\x{0308}/ig;
		s/\|/\x{0345}/ig;
	
		s/\*a/\x{0391}/ig;	s/a/\x{03B1}/ig;  
		s/\*b/\x{0392}/ig;	s/b/\x{03B2}/ig;
		s/\*g/\x{0393}/ig; 	s/g/\x{03B3}/ig;
		s/\*d/\x{0394}/ig; 	s/d/\x{03B4}/ig;
		s/\*e/\x{0395}/ig; 	s/e/\x{03B5}/ig;
		s/\*z/\x{0396}/ig; 	s/z/\x{03B6}/ig;
		s/\*h/\x{0397}/ig; 	s/h/\x{03B7}/ig;
		s/\*q/\x{0398}/ig; 	s/q/\x{03B8}/ig;
		s/\*i/\x{0399}/ig; 	s/i/\x{03B9}/ig;
		s/\*k/\x{039A}/ig; 	s/k/\x{03BA}/ig;
		s/\*l/\x{039B}/ig; 	s/l/\x{03BB}/ig;
		s/\*m/\x{039C}/ig; 	s/m/\x{03BC}/ig;
		s/\*n/\x{039D}/ig; 	s/n/\x{03BD}/ig;
		s/\*c/\x{039E}/ig; 	s/c/\x{03BE}/ig;
		s/\*o/\x{039F}/ig; 	s/o/\x{03BF}/ig;
		s/\*p/\x{03A0}/ig; 	s/p/\x{03C0}/ig;
		s/\*r/\x{03A1}/ig; 	s/r/\x{03C1}/ig;
		s/s\b/\x{03C2}/ig;
		s/\*s/\x{03A3}/ig; 	s/s/\x{03C3}/ig;
		s/\*t/\x{03A4}/ig; 	s/t/\x{03C4}/ig;
		s/\*u/\x{03A5}/ig; 	s/u/\x{03C5}/ig;
		s/\*f/\x{03A6}/ig; 	s/f/\x{03C6}/ig;
		s/\*x/\x{03A7}/ig; 	s/x/\x{03C7}/ig;
		s/\*y/\x{03A8}/ig; 	s/y/\x{03C8}/ig;
		s/\*w/\x{03A9}/ig; 	s/w/\x{03C9}/ig;
	
	}

	return wantarray ? @text : $text[0];
}

#
# incr: intelligently increment a line number
#
#       if n is numeric, add one
#       if n has mixed alpha-numeric parts, 
#         try to figure out what's going on
#
#       NB this is only run where no number 
#         has explicitly been given for the 
#         current line; so the editor thought
#         the number was easily deduced from
#         the previous one.

sub incr {

	my $n = shift;
		
	if ($n =~ /(\D*)(\d+)(\D*)?$/i) {
	
		my $pref = defined $1 ? $1 : "";
		my $n    = $2;
		my $suff = defined $3 ? $3 : "";
	
		return $pref . ($2 + 1);
	}
	else {
	
		return $n . "-1";
	}
}