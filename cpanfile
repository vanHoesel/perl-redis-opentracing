on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires            "Redis";
    requires            "Test::Most";
    requires            "Test::RedisServer";
};
