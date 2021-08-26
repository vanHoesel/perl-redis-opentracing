package Redis::OpenTracing;

use Moo;
use Types::Standard qw/Object/;

use Redis;
use OpenTracing::AutoScope;

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
    
    do {
        OpenTracing::AutoScope->start_guarded_span( uc($method_call) );
        
        return $self->redis->$method_call(@_);
        
    }
    #
    # this is a laymans way of doing it, there are no tags set, nor any other
    # useful information passed on... patches welcome!
}


sub DESTROY { } # we don't want this to be dispatched

1;
