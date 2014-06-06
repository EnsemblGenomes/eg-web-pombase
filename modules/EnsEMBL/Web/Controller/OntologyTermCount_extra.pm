package EnsEMBL::Web::Controller::OntologyTermCount_extra;

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
  my $callback = $hub->param('callback');
  
  my $dbc = $hub->get_databases('go')->{'go'}->dbc();
  my $sql = "select distinct termc.accession from term termp, term termc, closure_full where termp.term_id=closure_full.parent_term_id and termc.term_id=closure_full.child_term_id and termp.accession=?;";
  my $sth = $dbc->prepare($sql);
  $sth->bind_param(1, $query);
  $sth->execute();
  
  # Returns an array reference for all rows.
  my $goslims = $sth->fetchall_arrayref();
  
  $sth->finish();
  
  #print $callback . '( ' . $self->jsonify($goslims) . ' ) ';
  
  my $dbc_core = $hub->database('core')->dbc();
  $sql = sprintf('SELECT COUNT(DISTINCT object_xref.ensembl_id) FROM object_xref, xref WHERE object_xref.xref_id=xref.xref_id AND xref.dbprimary_acc IN (%s)', join(',', map '?', @{$goslims}));
  #print join(',', map '?', @{$goslims});
  #print $sql;
  
  my @goslim_ids;
  foreach my $term (@{ $goslims }) {
    push @goslim_ids, $term->[0];
  }
  
  #print join('\', \'', @goslim_ids);
  $sth = $dbc_core->prepare($sql);
  $sth->execute(@goslim_ids);
  
  my $goslimcount = $sth->fetchall_arrayref();
  $sth->finish();
  
  
  
  
  print $callback . '( ' . $self->jsonify($goslimcount) . ' ) ';
  return $self;
}

1;
