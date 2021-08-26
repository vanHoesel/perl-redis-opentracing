requires                "Moo";
requires                "OpenTracing::AutoScope";
requires                "Redis";
requires                "Types::Standard";

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires            "OpenTracing::Implementation";
    requires            "Test::Builder";
    requires            "Test::Deep";
    requires            "Test::MockObject";
    requires            "Test::Mock::Redis";
    requires            "Test::Most";
    requires            "Test::OpenTracing::Integration";
    requires            "Test::RedisServer";
    
};
