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

our $AUTOLOAD; # keep 'use strict' happy

sub AUTOLOAD {
    my $self = shift;
    
    my $method_call = do { $_ = $AUTOLOAD; s/.*:://; $_ };
    
    return $self->redis->$method_call(@_)
}


sub DESTROY { } # we don't want this to be dispatched

1;
