use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More;

use_ok 'App::Caoliu';

my $caoliu = App::Caoliu->new;
$caoliu->proxy('127.0.0.1:8087');
$caoliu->category('oumei');
is($caoliu->proxy,'127.0.0.1:8087','test proxy set value');
is($caoliu->feed,'http://t66y.com/rss.php?fid=4','test feed rss url');
is($caoliu->category,'oumei','test caoliu category set');
is(ref($caoliu->ua),'Mojo::UserAgent','test caoliu new user_agent');
is(ref($caoliu->parser),'App::Caoliu::Parser','test caoliu parser');

done_testing();
