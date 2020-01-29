package ADUsersCSV;

use strict;
use warnings;
use MCE::Flow;
use MCE;
use MCE::shared;
use File::Basename;
use Cwd qw( abs_path );
use Path::Tiny;
use File::FindLib 'lib/';
use IO::File;
use Text::CSV;
use MS2016 qw( Info Alert );
use Data::Dumper;
use Exporter qw(import);

our @EXPORT = qw(CountLines FilterOutToFile CreateUsersCSV);


sub CountLines {
    my $ifile = shift;

    my $count = 0;
    open(FILE, "<$ifile") or die "can't open $ifile: $!";
    $count += tr/\n/\n/ while sysread(FILE, $_, 2**16);
    close FILE;
    return $count;
}

sub FilterOutToFile {
    my ($args) = @_;

    my $in = $args->{in};
    my $out = $args->{out};
    my $pattern = $args->{pattern} || '^\$HEX\[(\d*[a-z]*)+\]$';
    my $abs_ifile = abs_path($in);
    my ($filename, $fpath, $ext) = fileparse($abs_ifile, '\..*');
    my $abs_ofile = path($fpath, $out);
    
    
    Info("No pattern specified, by default this will be filtered out: $pattern");
    
    my $regex = qr/(?i:$pattern)/;
    
    my $fh;

    my $counter1 = MCE::Shared->scalar( 0 );
    my $counter2 = MCE::Shared->scalar( 0 );

    mce_flow_f {
        chunk_size => '1m', max_workers => 'auto',
        use_slurpio => 1,
    },
    sub {
        my ( $mce, $chunk_ref, $chunk_id ) = @_;
        my ($numlines, $occurances ) = ( 0, 0 );
        
        open($fh, '>', $abs_ofile) or die "Couldn't open $abs_ofile $!";
        while ( $$chunk_ref =~ /([^\n]+\n)/mg ) {
            $numlines++;
            my $O = $1;
            if ( $O !~ $regex ) {
                print $fh $O;
                $occurances++;
            }
        }
        $counter1->incrby( $numlines );
        $counter2->incrby( $occurances );
        close $fh;

    }, $abs_ifile;

    my ($c1, $c2) = ($counter1->get(), $counter2->get());
    Info("# of words: $c1");
    Info("# of remaining words: $c2");
}

sub CreateUsersCSV {
    my ($args) = @_;
    my @inA;
    push @inA, $args->{in1};
    push @inA, $args->{in2};
    push @inA, $args->{in3};
    my $outFile = $args->{out};

    my @ous = split (/\s+/,<DATA>);
    
    our $minLength = CountLines($args->{in3});
    local *check = sub { 
        my @Files = @inA;
        do { Alert("File $_ must contain at least $minLength of names") && 
            exit if ( CountLines($_) lt $minLength ) } foreach (pop @Files);
    }->(@inA);
    
    
    my @fhs = map{IO::File->new($_) || die "$_: $!" } @inA;
    
    my $filehandler;
    open $filehandler, ">", $outFile or die " $outFile: $!";
    ## print csv header
    print $filehandler "firstname,lastname,password,username,ou\n";
    
    for ( 1 .. $minLength ) {
        my @lines = map{ scalar <$_>||''} @fhs or last;
        chomp @lines;
        $lines[3] = ucfirst($lines[0]).' '.ucfirst($lines[1]);

        my $item = int(rand($#ous));

        $lines[4] = qq/"CN=$lines[3],@ous[$item]"/;

        my $str = join ',', @lines;
        print $filehandler "$str\n";
    }

    close $filehandler or die "$outFile: $!";
}
1;

__DATA__
OU=helpdesk,OU=PRG,DC=MCKINSEY,DC=local OU=admin,OU=PRG,DC=MCKINSEY,DC=local OU=HR,OU=PRG,DC=MCKINSEY,DC=local