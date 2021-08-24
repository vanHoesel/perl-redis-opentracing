package Redis::OpenTracing;

use Moo;
use Types::Standard qw/Object/;

use Redis;

has 'redis' => (
    is => 'lazy',
    isa => Object, # beyond current scope to detect if it is a Redis like client
);

sub _build_redis {
    Redis->new
}


1;
