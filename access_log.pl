#!/usr/bin/perl -w

use strict;

my $file = shift;
open(LOG,"<$file") or die;

my $log   = [];
my $tLine = 1;

while(<LOG>)
{
    /^(.*) (.*) (.*) \[(.*)\] "(.*)" (.*) (.*) "(.*)" "(.*)"$/;
    my ($METHOD, $REQUEST_URL, $HTTP_VERSION) = split(/ /,$5);

    my $obj = AccessLog->new({
        REMOTE_HOST   => $1,
        FI            => $2,
        REMOTE_USER   => $3,
        DATE_TIME     => $4,
        METHOD        => $METHOD,
        REQUEST_URL   => $REQUEST_URL,
        HTTP_VERSION  => $HTTP_VERSION,
        HTTP_RESPONSE => $6,
        DATA_BYTES    => $7,
        REFERER       => $8,
        USER_AGENT    => $9,
    });
    push(@$log, $obj);

    $tLine++;
}

my $access = [];
my $all_access = [];
foreach (@$log) {
    if( $_->is_mobile ) {
        if( $_->is_not_static ) {
            if( $_->is_imode_brows_1 ) {
                push( @$access, $_ );
            }
            push( @$all_access, $_ );
        }
    }
}
print scalar @$access;
print "\n";
print scalar @$all_access;



package AccessLog;

use Carp;
use Class::Accessor;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors( qw(REMOTE_HOST FI REMOTE_USER DATE_TIME METHOD REQUEST_URL HTTP_VERSION HTTP_RESPONSE DATA_BYTES DATA_BYTES REFERER USER_AGENT) );

sub is_mobile {
    my $self = shift();
    return if(! $self->{REQUEST_URL});
    if ( $self->{REQUEST_URL} =~ m/\/staff\/m\// ) {
        return 1;
    }
}

sub is_imode_brows_1 {
    my $self = shift();
    if ( grep {$self->{USER_AGENT} =~ m/$_/} @{$self->imode_brows_1_target} ) {
        return 1;
    }
}

sub is_not_static {
    my $self = shift();
    return if ( $self->{REQUEST_URL} =~ m/static/ );
    return if ( $self->{REQUEST_URL} =~ m/png$/ );
    return if ( $self->{REQUEST_URL} =~ m/ico$/ );
    return if ( $self->{REQUEST_URL} =~ m/gif$/ );
    return if ( $self->{REQUEST_URL} =~ m/jpg$/ );
    return if ( $self->{REQUEST_URL} =~ m/\/staff\/sp\/js\/navi/ );
    return 1;
}

use constant imode_brows_1_target => [qw/
L10C
L01C
F08C
L04B
L03B
L02B
N06B
F09B
L06A
L04A
L03A
L01A
SH04A
SH03A
SH02A
SH01A
N05A
N04A
N03A
N02A
N01A
P10A
P06A
P05A
P04A
P03A
P02A
P01A
F10A
F07A
F06A
F05A
F04A
F03A
F02A
F01A
SH706iw
N706iII
SH706ie
N706ie
P706ie
NM706i
L706ie
P706imyu
SH706i
SO706i
N706i
F706i
SH906iTV
N906iL
N906i
F906i
N906imyu
SH906i
SO906i
P906i
L852i
F884iES
F884i
SH705iII
P705iCL
L705iX
SO705i
P705imyu
SH705i
L705i
N705i
D705imyu
D705i
P705i
F705i
F801i
P905iTV
F905iBiz
SO905iCS
SH905iTV
N905iBiz
N905imyu
SO905i
F905i
P905i
N905i
D905i
SH905i
L704i
P704i
D704i
SH704i
P704imyu
N704imyu
F704i
SO704i
L602i
P904i
D904i
F904i
N904i
SH904i
F883iS
F883iESS
F883iES
F883i
SO703i
N703imyu
P703imyu
SH703i
D703i
P703i
F703i
N703iD
N601i
L601i
SO903iTV
P903iX
F903iBSC
SH903iTV
P903iTV
F903iX
D903iTV
SO903i
F903i
D903i
N903i
P903i
SH903i
F882iES
N600i
L600i
D800iDS
SA800i
M702iG
M702iS
D702iF
P702iD
N702iS
SH702iS
SA702i
D702iBCL
SO702i
D702i
SH702iD
F702iD
N702iD
P702i
NM850iG
N902iL
N902iX
SH902iSL
SO902iWP+
F902iS
D902iS
N902iS
P902iS
SH902iS
SO902i
SH902i
P902i
N902i
D902i
F902i
N701iECO
D701iWM
P701iD
N701i
D701i
F881iES
D851iWM
P851i
SH851i
SA700iS
SH700iS
F700iS
P700i
N700i
SH700i
F700i
P901iTV
N901iS
P901iS
D901iS
F901iS
SH901iS
P901i
D901i
N901iC
F901iC
SH901iC
F880iES
N900iG
N900iL
F900iC
D900i
N900iS
P900iV
F900iT
SH900i
P900i
N900i
F900i
N2701
N2102V
F2102V
P2102V
N2051
F2051
T2101V
SH2101V
P2101V
D2101V
P2002
N2002
N2001
/];


