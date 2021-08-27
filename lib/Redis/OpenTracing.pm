package Redis::OpenTracing;

our $VERSION = 'v0.0.1';

use Moo;
use Types::Standard qw/Object/;

use Redis;
use OpenTracing::AutoScope;
use OpenTracing::GlobalTracer;
use Scalar::Util 'blessed';

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
        OpenTracing::AutoScope->start_guarded_span(
            blessed( $self->redis ) . '::' . $method_call
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
