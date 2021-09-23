package Redis::OpenTracing;

use strict;
use warnings;

use syntax 'maybe';

our $VERSION = 'v0.1.1';

use Moo;
use Types::Standard qw/Maybe Object Str is_Str/;

use OpenTracing::AutoScope;
use Scalar::Util 'blessed';



has 'redis' => (
    is => 'ro',
    isa => Object, # beyond current scope to detect if it is a Redis like client
    required => 1,
);



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
    
    my $dispatcher = $self->_get_dispatcher__peer_address( )
        or return;
    
    goto $dispatcher;
}

# add subrotines below to add more dispatcher, the name should be:
# '_build__peer_address__<redis_client_class_name>'



sub _build__peer_address__redis_fast {
    # we don't know how to compute a peer address, Redis::Fast does not give any
    # information about the connection, private methods are setters, not getters
    my $port = $_[0]->redis->info->{tcp_port};
    return "<unkown_host>:$port"
}


our $AUTOLOAD; # keep 'use strict' happy

sub AUTOLOAD {
    my $self = shift;
    
    my $method_call    = do { $_ = $AUTOLOAD; s/.*:://; $_ };
    my $component_name = $self->_redis_client_class_name( );
    my $db_statement   = uc($method_call);
    my $operation_name = $self->_operation_name( $method_call );
    my $peer_address   = $self->_peer_address( );
    
    my $method_wrap = sub {
        OpenTracing::AutoScope->start_guarded_span(
            $operation_name,
            tags => {
                'component'     => $component_name,
                'db.statement'  => $db_statement,
                'db.type'       => 'redis',
                maybe
                'peer.address'  => $peer_address,
                'span.kind'     => 'client',
            },
        );
        
        return $self->redis->$method_call(@_);
    };
    
    # Save this method for future calls
    no strict 'refs';
    *$AUTOLOAD = $method_wrap;
    
    goto $method_wrap;
}


# _get_dispatcher__peer_address
#
# returns the coderef of a defined subroutine for a Redis client class name
#
sub _get_dispatcher__peer_address {
    my $self = shift;
    my $class_name = $self->_redis_client_class_name( );
    my $dispatcher = do {
        $_ = $self->_redis_client_class_name( );
        s/::/_/;
        $_ = lc($_);
        '_build__peer_address__' . $_
    };
    
    return __PACKAGE__->can($dispatcher);
}



sub DESTROY { } # we don't want this to be dispatched



1;
