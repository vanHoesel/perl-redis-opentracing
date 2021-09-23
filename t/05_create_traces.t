use Test::Most;

use strict;
use warnings;

use OpenTracing::Implementation qw/Test/;
use Test::OpenTracing::Integration;

subtest "Create some traces" => sub {
    
    reset_spans;
    
    my $test_object = bless {}, 'MyTestApp';
    
    $test_object->get_some_keys( );
    
    global_tracer_cmp_easy(
        [
            {
                operation_name => 'MyTestApp::get_some_keys',
            },
            {
#               operation_name => re( qr/Test::Mock::Redis::NoOp::ping$/ ),
#               
#               It is not that object, it IS a Test::MockObject instead
#               
                operation_name => re( qr/Test::MockObject::ping$/ ),
                tags           => {
                    'component'     => 'Test::MockObject', # yep, Mocked again
                    'db.statement'  => 'PING',
                    'db.type'       => 'redis',
                    'peer.address'  => 'mocked',
                    'span.kind'     => 'client',
                }
            },
        ],
        "Got some expected spans"
    )
};

done_testing;



package MyTestApp;

use strict;
use warnings;

use lib 't/lib';

use OpenTracing::AutoScope;
use Redis::OpenTracing;
use Test::Mock::Redis::NoOp;

sub get_some_keys{
    OpenTracing::AutoScope->start_guarded_span( );
    
    my $self = shift;
    
    my $redis_test = Redis::OpenTracing->new(
        redis => Test::Mock::Redis::NoOp->mock_new( ),
    );
    $redis_test->ping;
    
}

# there should not be a __test_mockobject dispatcher inside Redis::OpenTracing
# that is why we add it here for the sake of the tests

BEGIN {
    no strict 'refs';
    *{ "Redis::OpenTracing::_build__peer_address__test_mockobject" } = sub {
        'mocked'
    }
}

1;
