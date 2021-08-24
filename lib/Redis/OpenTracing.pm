package Redis::OpenTracing;

use Moo;

use Types::Standard qw/Object/;

has 'redis' => (
    is => 'ro',
    isa => Object, # beyond current scope to detect if it is a Redis like client
);


1;
