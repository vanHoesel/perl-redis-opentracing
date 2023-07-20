use Test::More;
use Test::Exception;

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

note "so far, so good!";

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
    ],
   "... and we do have the expected spans" 
);



done_testing();
