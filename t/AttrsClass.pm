package AttrsClass;

use base qw(Oryx::Class);

our $schema = {
    attributes => [{
        name => 'attr_string',
        type => 'String',
    },{
        name => 'attr_complex',
        type => 'Complex',
    },{
        name => 'attr_integer',
        type => 'Integer',
    },{
        name => 'attr_float',
        type => 'Float',
        precision => 2,
    },{
        name => 'attr_boolean',
        type => 'Boolean',
    },{
        name => 'attr_datetime',
        type => 'DateTime',
        format => '%d-%m-%Y',
    }],
};

1;

