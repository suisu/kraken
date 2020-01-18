#!/usr/bin/perl -w
use strict;
use warnings;
use feature 'say';
use File::FindLib 'lib/';
use MS2016;
use Getopt::Long qw(GetOptions);
use Term::ANSIColor;
use Time::HiRes qw(time);
use Pod::Usage;


print<<INTRO;                                                       
               _                                     _ 
 ___ ___ _ _  | |_ ___ ___ ___ ___ ___   ___ _ _ _ _| |
|  _| . | | |_| '_|  _| .'| . | -_|   |_| . | | | | . |
|___|  _|___|_|_,_|_| |__,|_  |___|_|_|_|  _|_____|___|
    |_|                   |___|         |_|            

INTRO
my ($man, $help, $input_file, $output_folder) = (0,0,'', undef);

GetOptions('help|?' => \$help, 
            man => \$man,
            'file=s' => \$input_file,
            'out:s' => \$output_folder,
            'split|s!' => \(my $split = 0),
            'column|n:i' => \(my $column = -1),
            'delimiter|r:s' => \(my $delimiter = ':'),
            'debug|d!' => \$MS2016::debug,
            'color|c:i' => \$MS2016::color,
            'print|p:i' => \(my $print = 0),

) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(-message => "file must be specified!") if $input_file eq '';
my $start_time = time();
my %input_params;
$input_params{input} = $input_file;
$input_params{output} = $output_folder if $output_folder;

my $linkedin = MS2016->new({
    %input_params
});

$linkedin->check_parameters();

if ( $print gt 0 ) {
    $linkedin->read_n_lines($print);
    exit;
}

$linkedin->run({split_column=>$split, 
                separator=>$delimiter,
                use_column=>$column});

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
       -file       input file [mandatory]
       -out        out folder, default: input file folder [optional]
       -split      if file contains more columns, split=1,[optional], default 0
       -column     if file contains more columns, column containing password, default: last [optional]
       -delimiter  if file contains more columns, separator, default ':' [optionnal]
       -debug      debug on|off, default off [optional]
       -print     print first n lines from file, default 0 (off), [optional]

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-file>

Input file containing passwords to filter.

=item B<-out>

Output folder, [optional]

=item B<-column>

If more columns in a file, column containing passwords, [optionnal], default: last column

=item B<-delimiter>

If more columns in a file, column separator, [optional], default: ':'

=item B<-debug>

Debug ON|OFF, [optional], default: 0 (OFF)

=item B<-print>

Print first n lines from a file, to check file before filtering, [optional], default: last column

=back

=head1 DESCRIPTION

B<This program> will read the given input file and filter passing passwords for MS2016 password policy rules

=cut

=head1 AUTHOR

Monika Mueller

=cut

