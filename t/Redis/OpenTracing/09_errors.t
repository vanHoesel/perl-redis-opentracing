use Test::More;
use Test::Exception;
use Test::Deep qw/superhashof/;

use lib 't/lib';

use OpenTracing::Implementation qw/Test/;
use Test::OpenTracing::Integration;
use Test::Mock::Redis::NoOp;

use Redis::OpenTracing;

my $redis;

lives_ok {
    $redis = Redis::OpenTracing->new(
        redis => Test::Mock::Redis::NoOp->mock_new(),
    );
} "Instatiated and wrapped `Redis::NoOp` inside `Redis::OpenTracing`";

is $redis->ping, "PONG",
    "... and seems to be okay";

throws_ok {
    $redis->die("Nope, not doing this");
} qr/Nope, not doing this/,
    "... and dies with the appropriate message";

global_tracer_cmp_easy(
    [
        {
            operation_name  => "Test::MockObject::ping",
            tags            => {
                'component'     => "Test::MockObject",
                'db.statement'  => "PING",
                'db.type'       => "redis",
                'span.kind'     => "client",
            },
        },
        {
            operation_name  => "Test::MockObject::die",
            tags            => {
                'component'     => "Test::MockObject",
                'db.statement'  => "DIE",
                'db.type'       => "redis",
                'span.kind'     => "client",
                
                'error'         => 1,
                'message'       => "Nope, not doing this",
                'error.kind'    => "REDIS_DIE_EXCEPTION"
            },
        }
    ],
   "... and we do have the expected spans" 
);



done_testing();
