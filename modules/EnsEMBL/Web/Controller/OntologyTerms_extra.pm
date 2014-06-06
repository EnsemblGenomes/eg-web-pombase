package EnsEMBL::Web::Controller::OntologyTerms_extra;

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
  $sql = sprintf('SELECT distinct gene.stable_id, dx.display_label, gene.description, ontology_xref.linkage_type FROM object_xref, xref ox, ontology_xref, gene, transcript, xref dx WHERE object_xref.xref_id=ox.xref_id AND object_xref.ensembl_object_type="Transcript" AND object_xref.ensembl_id=transcript.transcript_id AND transcript.gene_id=gene.gene_id AND transcript.display_xref_id=dx.xref_id AND object_xref.object_xref_id=ontology_xref.object_xref_id AND ox.dbprimary_acc IN (%s)', join(',', map '?', @{$goslims}));
  #print join(',', map '?', @{$goslims});
  #print $sql;
  
  my @goslim_ids;
  foreach my $term (@{ $goslims }) {
    push @goslim_ids, $term->[0];
  }
  
  #print join('\', \'', @goslim_ids);
  $sth = $dbc_core->prepare($sql);
  $sth->execute(@goslim_ids);
  
  my $goslimfull = $sth->fetchall_arrayref();
  $sth->finish();
  
  
  
  
  print $callback . '( ' . $self->jsonify($goslimfull) . ' ) ';
  return $self;
}

1;
