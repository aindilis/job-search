#!/usr/bin/perl -w

use Workflow::Factory qw( FACTORY );

# Defines a workflow of type 'myworkflow'
my $workflow_conf  = 'workflow.xml';
# Defines actions available to the workflow
my $action_conf    = 'action.xml';
# Defines conditions available to the workflow
my $condition_conf = 'condition.xml';
# Defines validators available to the actions
my $validator_conf = 'validator.xml';

# Stock the factory with the configurations; we can add more later if
# we want
FACTORY->add_config_from_file(
			      workflow   => $workflow_conf,
			      action     => $action_conf,
			      condition  => $condition_conf,
			      validator  => $validator_conf
			     );

# Instantiate a new workflow...
my $workflow = FACTORY->create_workflow( 'myworkflow' );
print "Workflow ", $workflow->id, " ",
  "currently at state ", $workflow->state, "\n";

# Display available actions...
print "Available actions: ", $workflow->get_current_actions, "\n";

# Get the data needed for action 'upload file' (assumed to be
# available in the current state) and display the fieldname and
# description

print "Action 'upload file' requires the following fields:\n";
foreach my $field ( $workflow->get_action_fields( 'FOO' ) ) {
  print $field->name, ": ", $field->description,
    "(Required? ", $field->is_required, ")\n";
}

# Add data to the workflow context for the validators, conditions and
# actions to work with

my $context = $workflow->context;
$context->param( current_user => $user );
$context->param( sections => \@sections );
$context->param( path => $path_to_file );

# Execute one of them
$workflow->execute_action( 'upload file' );

print "New state: ", $workflow->state, "\n";

# Later.... fetch an existing workflow
my $id = get_workflow_id_from_user( ... );
my $workflow = FACTORY->fetch_workflow( 'myworkflow', $id );
print "Current state: ", $workflow->state, "\n";

