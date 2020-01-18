package MS2016;

use strict;
use warnings;

use Time::Piece;
use MCE;
use MCE::Flow;
use MCE::Shared;
use File::Basename;
use File::Type;
use feature "switch";
use Readonly;
use Path::Tiny;
use Cwd qw(cwd);
use Term::ANSIColor;
#use Data::Dumper;

use Exporter qw(import);

our @EXPORT = qw(Alert Info OK);
our ($debug, $color) = (0,1);
Readonly our $output_file_postfix => "_out.txt";

sub Alert {
    my $message = shift;
    _Color('bold red', '[!] ', $message);
}

sub Info {
    my $message = shift;
    _Color('bold yellow', '[*] ', $message);
}

sub Debug {
    if ( $debug eq 1) {
        _Color('bold blue', '[$] ', (caller(1))[3]);
    }
}

sub OK {
    my $message = shift;
    _Color('bold green', '[OK] ', $message);
}

sub _Color {
    my ($color_, $mark, $message) = @_;
    print color($color_) if $color eq 1;
    print($mark);
    print color('reset') if $color eq 1;
    print "$message\n";
}

sub new {
    my ($class, $args) = @_;
    my $self = {
        _input_file => $args->{input},
        _output_folder => $args->{output} || cwd,
        _output_file => '',
        _cores => MCE::Util::get_ncpu,
    };
    my $object = bless $self, $class;
    $object->_set_datetime;
    $object->_set_output_file;
    return $object;
}


sub get_input_file {
    my $self = shift;
    return $self->{_input_file};
}

sub set_input_file {
    my ($self, $input_file) = @_;
    $self->{_input_file} = $input_file;
}

sub _set_datetime {
    my $self = shift;
    my $t = localtime;
    $self->{datetime} = $t->datetime;
}

sub get_datetime {
    my $self = shift;
    return $self->{datetime};
}

sub set_output_folder {
    my ($self, $output_folder) = @_;
    $self->{_output_folder} = $output_folder;
}

sub get_output_folder {
    my $self = shift;
    return $self->{_output_foler};
}

sub check_parameters {
    my $self = shift;
    Debug();

    if (not -d $self->{_output_folder} ) {
        Alert("Output folder $self->{_output_folder} does not exist");
    }
    if (not -e $self->{_input_file} ) {
        Alert("Input file $self->{_output_folder} does not exist");
        exit;
    }
    Alert("Current no of cores: $self->{_cores}");
    Info("Check OK");
}

sub read_n_lines {
    my ($self, $lines) = @_;
    Debug();

    $lines ||= 10;
    my $count = 0;
    open my $fh, '<', $self->{_input_file} or 
        die "Cannot open $self->{_input_file} $!";
    Info("Reading first $lines from $self->{_input_file}");
    while ( <$fh> ) {
        print;
        last if ++$count == $lines;
    }
}

sub _set_output_file {
    my $self = shift;

    my ($filename, $fpath, $ext) = fileparse($self->{_input_file}, '\..*');
    my $newfile = join '',"$filename","$output_file_postfix";
    $self->{_output_file} = path($fpath, $newfile);
}


sub _block_processor_split {
    my ($self, $args) = @_;
    Debug();

    my $ifile          = $args->{ifile};
    my $split_column   = $args->{split_column};
    my $delimiter      = $args->{delimiter};
    my $use_column     = $args->{use_column};
    
    my $counter1 = MCE::Shared->scalar( 0 );
    my $counter2 = MCE::Shared->scalar( 0 );
    my $fh;

    mce_flow_f {
        chunk_size => '1m', max_workers => $self->{_cores},
        use_slurpio => 1,
    },
    sub {
        my ( $mce, $chunk_ref, $chunk_id ) = @_;
        my ( $numlines, $occurances ) = ( 0, 0 );

        open($fh, '>', $self->{_output_file}) or die "Could not open $self->{_output_file} $!";
        while ( $$chunk_ref =~ /(?<line>[^\n]+\n)/mg ) {
            $numlines++;
            my @temp = $split_column eq 1 ? split/$delimiter/, $+{line} : ($+{line});
            if ( $temp[$use_column] =~ m/^(?=.{12,}$)(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?!.*(.)\1{3})(?=.*?[^\w\s])(?-i)(?i-msnx:(?!.*pass|.*password|.*word|.*w0rd|.*mckinsey|.*letmein|.*qwerty|.*januray|.*london|.*trustno|.*iloveyou|.*hello|.*1234|.*1Q2w3e4r5t6y)).*/ ) {
                print $fh $temp[$use_column];
                $occurances++;
            }
        }
        $counter1->incrby( $numlines );
        $counter2->incrby( $occurances );   
        close $fh;

    }, $ifile;
    my ($c1, $c2) = ($counter1->get(), $counter2->get());
    Info("# of words: $c1");
    Info("# of matched words: $c2");
    Info("The output file: $self->{_output_file} is generated");
    Alert("Nothing found") if $c2 le 0;
}


sub run {
    my ($self, $args) = @_;
    Debug();

    my $split_column   = $args->{split_column};
    my $delimiter      = $args->{separator} || ':';
    my $use_column     = $args->{use_column} || -1;

    my $ftype = File::Type->new();
    my $file_type = $ftype->mime_type($self->{_input_file});

    if ($file_type eq 'application/octet-stream') {
        Info("Your file $self->{_input_file} is a plain text file");
        $self->_block_processor_split({ifile=>$self->{_input_file},
                split_column=>$split_column,
                delimiter=>$delimiter,
                use_column=>$use_column});
    } elsif ($file_type eq 'application/zip') {
        Info("Your file $self->{_input_file} is a zip file and will be unpacked");
        open my $fh, "unzip -p $self->{_input_file} |" 
            or die "The $self->{_input_file} cannot be unpacked $!";
        $self->_block_processor({
            ifile=>$fh, 
            split_column=>$split_column,
            delimiter=>$delimiter,
            use_column=>$use_column
            });
    }
}
1;
