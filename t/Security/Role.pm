package Security::Role;

use base qw(Oryx::Class);

our $schema = {
    attributes => [{
        name => 'rolename',
        type => 'String',
    }],
    associations => [{
        type => 'Array',
        class => 'Security::Permission',
        role => 'my_perms',
    }]
};

1;
