package App::Caoliu::Downloader;

# ABSTRACT: caoliu download tool
use Mojo::Base 'Mojo';
use Carp;
use Mojo::UserAgent;
use Mojo::Util;
use File::Spec;
use Data::Dumper;
use Mojo::IOLoop;
use Mojo::Collection;

# defined constant var
sub RM_DOWNLOAD_PHP () { 'http://www.rmdown.com/download.php' }

has ua => sub { Mojo::UserAgent->new };
has timeout => 60;
has rmdown  => 'http://www.rmdown.com';
has proxy   => '127.0.0.1:8087';
has agent =>
'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.802.30 Safari/535.1 SE 2.X MetaSr 1.0';
has log => sub {
    $ENV{LOGGER} || do {
        require Mojo::Log
          && Mojo::Log->new->level( $ENV{LOGGER_LEVEL} || 'info' );
      }
};

sub download_torrent {
    my ( $self, $url, $path ) = @_;

    Carp::croak("please input the torrent url link") unless $url;
    Carp::croak("path not exists: $path") unless -e $path;

    return unless $url =~ m{rmdown};

    my $headers = {
        User_Agent   => $self->agent,
        Referer      => $url,
        Origin       => $self->rmdown,
        Content_Type => 'form-data',
    };
    my $post_form = {};

    # get refvalue and reffvalue for post_form
    my $tx = $self->ua->get( $url => $headers );
    if ( my $res = $tx->success ) {
        my $html = $res->body;
        if ( $html =~ m/(<INPUT.+?name=['"]?ref['"]?.*?>)/gi ) {
            my $tmp = $1;
            $post_form->{ref} = $1
              if ( $tmp =~ m/(?<=value=)["']?([^\s>'"]+)/gi );
        }
        if ( $html =~ m/(<INPUT.+?name=['"]?ref['"]?.*?>)/gi ) {
            my $tmp = $1;
            $post_form->{reff} = $1
              if ( $tmp =~ m/(?<=value=)["']?([^\s>'"]+)/gi );
        }
    }
    else {
        $self->log->error("get reffvalue failed,check ....");
        return;
    }

    # construct post_from and submit post request to rmdownload
    # download file here, and return filename md5
    $post_form->{submit} = 'download';
    $self->log->debug(
        "send http_reqeust to rmdown with form" . Dumper($post_form) );
    $tx = $self->ua->post( +RM_DOWNLOAD_PHP, $headers => form => $post_form );
    if ( $tx->success ) {
        $self->log->debug("post rmdownload link successful!");
        if ( $tx->res->headers->content_disposition =~
            m/(?<=filename=)["']?([^\s>'"]+)/gi )
        {
            my $tmpfile = $1;
            return
              unless $tx->res->content->asset->move_to(
                File::Spec->catfile( $path, $tmpfile ) );
            $self->log->debug("finish download file $tmpfile");
            return $tmpfile;
        }
    }
    else {
        $self->log->error( "download failed,return response" . $tx->res->body );
    }

    return;
}

sub parallel_get {
    my $self  = shift;
    my %param = @_;
    my @urls  = keys %param;

    # Blocking parallel requests (does not work inside a running event loop)
    if (@urls) {
        my $delay = Mojo::IOLoop->singleton;
        for my $url( Mojo::Collection->new(@urls)->shuffle->each ) {
            $delay->begin;
            $self->ua->get(
                $url => sub {
                    my ( $ua, $tx ) = @_;
                    if ( my $res = $tx->success ) {
                        $param{$url}->($url,$ua,$res);
                    }
                    else {
                        $self->log->error("parallel get url => $_ failed");
                    }
                    $delay->stop;
                }
            );
        }
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
    }
}

1;
