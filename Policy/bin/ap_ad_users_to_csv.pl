#!/usr/bin/perl -w
use strict;
use warnings;
use feature 'say';
use File::FindLib 'lib/';
use MS2016 qw(Info);
use Getopt::Long qw(GetOptions);
use Term::ANSIColor;
use Time::HiRes qw(time);
use Pod::Usage;
##
use Data::Dumper;
use ADUsersCSV qw(CountLines FilterOutToFile CreateUsersCSV);

print<<INTRO;                                                       
               _                                     _ 
 ___ ___ _ _  | |_ ___ ___ ___ ___ ___   ___ _ _ _ _| |
|  _| . | | |_| '_|  _| .'| . | -_|   |_| . | | | | . |
|___|  _|___|_|_,_|_| |__,|_  |___|_|_|_|  _|_____|___|
    |_|                   |___|         |_|            

INTRO
my ($man, $help, $count) = (0,0,undef);
my %filesFilter;
my %filesMerge;

GetOptions('help|?' => \$help, 
            man => \$man,
            'count=s' => \$count,
            'filter=s' => \%filesFilter,
            'merge=s' => \%filesMerge,
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

my $start_time = time();


my $cnt = CountLines($count) if defined $count;
Info("File $count has: $cnt rows") if defined $count;

FilterOutToFile(\%filesFilter) if keys %filesFilter;

CreateUsersCSV(\%filesMerge) if keys %filesMerge;


my $elapsed_time = time() - $start_time;
MS2016::OK("---- Script finished ---- | Time elapsed: $elapsed_time sec");


__END__

=head1 NAME

ap_ms2016 - Filters valid password for Microsoft Server 2016


=head1 SYNOPSIS

ap_ms2016 [options]

     Options:

       -help       brief help message
       -man        full documentation
       -count      file
       -filter     in=file [mandatory] out=file [mandatory] pattern=<regex> [optional]
       -merge      in1=file1 in2=file2 in3=file3 out=file_out [all mandatory]

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-count>

ap_ad_users_to_csv -c file.txt, returns number of lines in the file.txt

=item B<-filter>

ap_ad_users_to_csv --filter in=file.txt 
                   --filter out=out_file.txt 
                   --filter pattern=<regex>[optionnal].
Generates an out_file.txt with words not containing pattern.

=item B<-merge>

ap_ad_user_to_csv --merge in1=file1.txt 
                  --merge in2=file2.txt 
                  --merge in3=file3.txt
                  --merge out=out_file.csv
E.g. file1.txt containing all first names, file2.txt containing all surnames,
file3.txt all passwords, out_file.csv generates CSV file with columns:
First name | Last name | password | username | OU

=back

=head1 DESCRIPTION

B<This program> Filters files , calculates no of lines in a file (more efficient than wc -l), 
generates CSV file for importing AD DC users further prepared for PowerShell.

=cut

=head1 AUTHOR

Monika Mueller

=cut

