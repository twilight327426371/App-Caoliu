package App::Caoliu;

# ABSTRACT: a awsome module,suck greate fire wall!
use Mojo::Base "Mojo";
use Mojo::Home;
use Mojo::UserAgent;
use Mojo::Log;
use Mojo::Util;
use Mojo::URL;
use Mojo::Path;
use Mojo::UserAgent::CookieJar;
use App::Caoliu::RSS;

sub RM_DOWNLOAD_PHP () { 'http://www.rmdown.com/download.php' }
has ua => sub { Mojo::UserAgent->new };
has timeout  => 60;
has proxy    => '127.0.0.1:8087';
has log      => sub { Mojo::Log->new };
has category => [qw( wuma youma donghua oumei)];
has parser   => sub { App::Caoliu::Parser->new };
has feed     => 'http://t66y.com/rss.php?fid=2';
has url      => 'http://t66y.com';
has home     => sub { Mojo::Home->new };
has downloader => sub { App::Caoliu::Downloader->new };

sub new {
    my $self = shift->SUPER::new(@_);
    my $home = $self->home->detect( ref $self );

    $self->log->path( $home->rel_file('log/caoliu.log') )
      if -w $home->rel_file('log');
    return $self;
}

sub generate_torrent{
    my ($self,$download_link,$path) = @_;

}
1;

=pod

=head1 NAME

=head1 DESCRIPTION

=head1 USAGE 

=cut
