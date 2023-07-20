use Test::More;

use OpenTracing::Implementation qw/Test/;

use Test::OpenTracing::Integration;
use Test::Mock::Redis;

use Redis::OpenTracing;



# create your 'wrapped' Redis client
#
my $redis = Redis::OpenTracing->new(
    redis => Test::Mock::Redis->new(),
    tags  => { tag_1 => 1, tag_2 => 2},
);



# do your usual stud, as always
#
$redis->ping;
$redis->set( key_1 => "Hello" );
$redis->multi;
$redis->rpush( key_2 => 1 .. 5 );
$redis->hset( key_3 => foo => 7, bar => 8);
my @resp = $redis->exec;
my @keys = $redis->keys('');


pass "so far, so good!";

# and now see that we have spans
#
global_tracer_cmp_easy(
    [
        {
            operation_name  => "Test::Mock::Redis::ping",
            tags            => {
                'component'     => "Test::Mock::Redis",
                'db.statement'  => "PING",
                'db.type'       => "redis",
                'span.kind'     => "client",
                'tag_1'         => "1",
                'tag_2'         => "2",
            },
        },
        {
            operation_name  => "Test::Mock::Redis::set",
            tags            => {
                'component'     => "Test::Mock::Redis",
                'db.statement'  => "SET",
                'db.type'       => "redis",
                'span.kind'     => "client",
                'tag_1'         => "1",
                'tag_2'         => "2",
            },
        },
        {
            operation_name  => "Test::Mock::Redis::multi",
            tags            => {
                'component'     => "Test::Mock::Redis",
                'db.statement'  => "MULTI",
                'db.type'       => "redis",
                'span.kind'     => "client",
                'tag_1'         => "1",
                'tag_2'         => "2",
            },
        },
        {
            operation_name  => "Test::Mock::Redis::rpush",
            tags            => {
                'component'     => "Test::Mock::Redis",
                'db.statement'  => "RPUSH",
                'db.type'       => "redis",
                'span.kind'     => "client",
                'tag_1'         => "1",
                'tag_2'         => "2",
            },
        },
        {
            operation_name  => "Test::Mock::Redis::hset",
            tags            => {
                'component'     => "Test::Mock::Redis",
                'db.statement'  => "HSET",
                'db.type'       => "redis",
                'span.kind'     => "client",
                'tag_1'         => "1",
                'tag_2'         => "2",
            },
        },
        {
            operation_name  => "Test::Mock::Redis::exec",
            tags            => {
                'component'     => "Test::Mock::Redis",
                'db.statement'  => "EXEC",
                'db.type'       => "redis",
                'span.kind'     => "client",
                'tag_1'         => "1",
                'tag_2'         => "2",
            },
        },
        {
            operation_name  => "Test::Mock::Redis::keys",
            tags            => {
                'component'     => "Test::Mock::Redis",
                'db.statement'  => "KEYS",
                'db.type'       => "redis",
                'span.kind'     => "client",
                'tag_1'         => "1",
                'tag_2'         => "2",
            },
        },
    ],
   "... and we do have spans" 
);



done_testing();
