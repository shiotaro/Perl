#!/usr/bin/perl

use strict;

use Email::MIME;
use Email::MIME::XPath;
use Email::MIME::ContentType;
use JSON::XS;
use Time::Piece;
use Encode;
use Image::Magick;

=memo

"(time)_$$/body" preserves it here.

Some images are preserved by "(time)_$$/file_1,file_2,...".

Please change $DIR to a suitable directory.

=cut

my $MAIL = join '', <STDIN>;

my $DIR = '/home/photo/public_html/blog_data';
my $time = time();

my $mail = Email::MIME->new($MAIL) or die "error - $!";

# MessageID
my $id = $mail->header('Message-Id');

# Subject
my $subject = $mail->header('Subject');

# image rotate check.
my $image_rotate;
if( $subject =~ m/\{imagerotate\}/ ) {
	$image_rotate = 1;
	$subject =~ s/\{imagerotate\}//;
}

# From
my $from = do {
	$mail->header('From') =~ /([^<]+\@(?:[-a-z0-9]+\.)*[a-z]+)/;
	$1
};

# Body
my ($body_data) = $mail->xpath_findnodes('//*[@content_type=~"^text"][1]');
if( ! $body_data ) {
	($body_data) = $mail->xpath_findnode('//*[@content_type=~"^html"][1]');
}

my $body = '';
if( $body_data ) {
	$body = Encode::decode(
		parse_content_type($body_data->content_type)->{attributes}->{charset},
		$body_data->body,
	);
}

# Make dir
my $local_time_piece = localtime();
my $target_dir = $DIR. '/' .$local_time_piece->date;
if( not -d $target_dir ) {
	umask(0);
	mkdir( $target_dir, 0777 ) or die $!;
}

my $image_parts = [];
@$image_parts = $mail->xpath_findnodes('//*[@content_type=~"^image/"]');

my $file_array = [];
for( my $i = 0; $i < scalar @$image_parts; $i++ ) {
	my $image_data = $image_parts->[$i];

	my $filename = $image_data->filename;

	my $image_dir = "$target_dir\/". $time;
	if( not -d $image_dir ) {
		umask(0);
		mkdir( $image_dir, 0777 ) or die $!;
	}


	my $save_file = "$image_dir\/$filename";
	open( FH, ">$save_file" );
	print FH $image_data->body;
	close FH;

	# create thumb.
	my $image = Image::Magick->new();
	$image->Read( $save_file );
	
	# image rotate.
	if( $image_rotate ) {
		$image->Rotate(degrees=>-90,crop=>1);
	}
	
	# size check.
	if( $image->Get('width') lt $image->Get('height') ) {
		$image->Scale(geometry=>180);
	} else {
		$image->Scale(geometry=>240);
	}
	# out put
	$image->Write( $image_dir. '/thumb_'. $filename );

	push( @$file_array, $filename );

}

# create json
my $json_hash = {};
$json_hash->{'message_id'} = $id;
$json_hash->{'subject'}    = $subject;
$json_hash->{'from'}       = $from;
$json_hash->{'body'}       = $body;
if( scalar @$file_array ) {
 $json_hash->{'file_array'} = $file_array;
}

# data dump
my $out_file_name = "$target_dir\/". $time. '.json';
open( my $FH, ">$out_file_name" ) or die "file open error - $!";
print $FH JSON::XS->new->utf8->encode ($json_hash);
close $FH;
chmod (0666 , $out_file_name);


1;

