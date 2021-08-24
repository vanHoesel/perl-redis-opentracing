use Test::Most;
use Test::Mock::Redis;

use Redis::OpenTracing;

can_ok( 'Redis::OpenTracing', qw/new/ );

subtest 'Create new client... with Redis' => sub {
    
    my $redis_client = Test::Mock::Redis->new;
    my $redis_tracer;
    
    lives_ok {
        $redis_tracer = Redis::OpenTracing->new( redis => $redis_client )
    } "Can call 'new' with a Redis Client";
    
    isa_ok $redis_tracer, 'Redis::OpenTracing',
        "... and returns a 'Redis::OpenTracing' client";
    
    isa_ok $redis_tracer->redis, "Test::Mock::Redis",
        "... and the internal client is our 'Test::Mock::Redis'";
    
};

subtest 'Create new client... without' => sub {
    
    my $redis_tracer;
    
    lives_ok {
        $redis_tracer = Redis::OpenTracing->new( )
    } "Can call 'new'";
    
    isa_ok $redis_tracer, 'Redis::OpenTracing',
        "... and returns a 'Redis::OpenTracing' client";
    
    isa_ok $redis_tracer->redis, "Redis",
        "... and the internal client is a 'Redis' instance";
    
};

done_testing( );
