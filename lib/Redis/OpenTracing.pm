package Redis::OpenTracing;

use strict;
use warnings;

use syntax 'maybe';

our $VERSION = 'v0.0.2';

use Moo;
use Types::Standard qw/Maybe Object Str is_Str/;

use Redis;
use OpenTracing::AutoScope;
use OpenTracing::GlobalTracer;
use Scalar::Util 'blessed';



has 'redis' => (
    is => 'lazy',
    isa => Object, # beyond current scope to detect if it is a Redis like client
);

# _build_redis()
#
# returns a (auto-connected) Redis instance. We may opt for Redis::Fast instead,
# but will leave that for a later itteration. It is always possible to
# instantiate any client and inject it inti the constructor.
#
sub _build_redis {
    Redis->new
}



has '_redis_client_class_name' => (
    is => 'lazy',
    isa => Str,
);

sub _build__redis_client_class_name {
    blessed( shift->redis )
};



sub _operation_name {
    my ( $self, $method_name ) = @_;
    
    return $self->_redis_client_class_name . '::' . $method_name;
}



has '_peer_address' => (
    is => 'lazy',
    isa => Maybe[ Str ],
);

sub _build__peer_address {
    my ( $self ) = @_;
    
    return "@{[ $self->redis->{ server } ]}"
        if exists $self->redis->{ server };
    # currentl, we're fine with any stringification of a blessed hashref too
    # but for Redis, Redis::Fast, Test::Mock::Redis, this is just a string
    
    return
}



our $AUTOLOAD; # keep 'use strict' happy

sub AUTOLOAD {
    my $self = shift;
    
    my $method_call = do { $_ = $AUTOLOAD; s/.*:://; $_ };
    
    OpenTracing::AutoScope->start_guarded_span(
        $self->_operation_name( $method_call ),
        tags => {
            'component'     => __PACKAGE__,
            'db.statement'  => uc($method_call),
            'db.type'       => 'redis',
            maybe
            'peer.address'  => $self->_peer_address( ),
            'span.kind'     => 'client',
        },
    );
    
    return $self->redis->$method_call(@_);
    
    # this is a laymans way of doing it, there are no tags set, nor any other
    # useful information passed on... patches welcome!
}



sub DESTROY { } # we don't want this to be dispatched



1;
