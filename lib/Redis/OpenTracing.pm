package Redis::OpenTracing;

use strict;
use warnings;

our $VERSION = 'v0.0.1';

use Moo;
use Types::Standard qw/Object Str/;

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



our $AUTOLOAD; # keep 'use strict' happy

sub AUTOLOAD {
    my $self = shift;
    
    my $method_call = do { $_ = $AUTOLOAD; s/.*:://; $_ };
    
    do {
        OpenTracing::AutoScope->start_guarded_span(
            $self->_operation_name( $method_call )
        );
        
        OpenTracing::GlobalTracer
            ->get_global_tracer( )
            ->get_active_span
            ->add_tags(
                'component'     => __PACKAGE__,
                'db.statement'  => uc($method_call),
                'db.type'       => 'redis',
                'span.kind'     => 'client',
            )
        ;
        
        return $self->redis->$method_call(@_);
        
    }
    #
    # this is a laymans way of doing it, there are no tags set, nor any other
    # useful information passed on... patches welcome!
}



sub DESTROY { } # we don't want this to be dispatched



1;
