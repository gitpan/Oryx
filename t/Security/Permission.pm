package Security::Permission;

use base qw(Oryx::Class);

our $schema = {
    attributes => [{
        name => 'permname',
        type => 'String',
    }],
};

1;
