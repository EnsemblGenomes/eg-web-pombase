package EnsEMBL::Web::Controller::GOtermQuery;

### Provides JSON results for protein weight range

use strict;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;

use base qw(EnsEMBL::Web::Controller);

sub new {
  my $class = shift;
  my $self  = {};
  
  bless $self, $class;
  
  my $hub      = new EnsEMBL::Web::Hub;
  my $query = $hub->param('q');
  my $callback = $hub->param('callback');
  
  my $dbc = $hub->get_databases('go')->{'go'}->dbc();
  my $sql = "select t.accession, t.name, t.definition, o.name, o.namespace from term t, ontology o where t.ontology_id=o.ontology_id and t.accession=?";
  my $sth = $dbc->prepare($sql);
  $sth->bind_param(1, $query);
  $sth->execute();
  
  # Returns an array reference for all rows.
  my $possible_terms = $sth->fetchall_arrayref();
  
  $sth->finish();
  
  print $callback . '( ' . $self->jsonify($possible_terms) . ' ) ';
  return $self;
}

1;
