package EnsEMBL::Web::Controller::OntologyTerms;

### Provides JSON results for all matching ontology terms

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
  my $ontology = $hub->param('o');
  my $callback = $hub->param('callback');
  
  my $dbc = $hub->get_databases('go')->{'go'}->dbc();
  my $sql = "select distinct term.accession, term.name from term, ontology where term.ontology_id=ontology.ontology_id";
  
  my @query_terms = split(/ /, $query);
  foreach my $q ( @query_terms ) {
    $sql .= ' and term.name like ?';
  }
  $sql .= ' and ontology.name=?;';
  
  my $sth = $dbc->prepare($sql);
  my $binding_param = 1;
  foreach my $q ( @query_terms ) {
    $sth->bind_param($binding_param, '%'.$q.'%');
    $binding_param += 1;
  }
  $sth->bind_param($binding_param, $ontology);
  $sth->execute();
  
  # Returns an array reference for all rows.
  my $goslims = $sth->fetchall_arrayref();
  
  $sth->finish();
  
  print $callback . '( ' . $self->jsonify($goslims) . ' ) ';
  return $self;
}

1;
