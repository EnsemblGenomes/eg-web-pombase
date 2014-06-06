package EnsEMBL::Web::Controller::GOSlimTerms;

### Provides JSON results for all GO slims

use strict;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;

use base qw(EnsEMBL::Web::Controller);

sub new {
  my $class = shift;
  my $self  = {};
  
  bless $self, $class;
  
  my $hub      = new EnsEMBL::Web::Hub;
  my $callback = $hub->param('callback');
  
  my $dbc = $hub->get_databases('go')->{'go'}->dbc();
#  my $sql = "select distinct term.accession, term.name, ont.namespace from term, ontology ont, aux_GO_goslim_pombe_map slim where term.ontology_id=ont.ontology_id and slim.subset_term_id=term.term_id;";
  my $sql = "select parent_accession, parent_name, namespace, rel_type, child_accession from (select distinct parent.term_id, parent.accession parent_accession, parent.name parent_name, ont.namespace, IF(relation_type.name IS NULL, '', relation_type.name) rel_type, IF(relation_type.name IS NULL, '', child.accession) child_accession from term parent join ontology ont on (ont.ontology_id=parent.ontology_id) join (select distinct subset_term_id from aux_GO_goslim_pombe_map) slim on (slim.subset_term_id=parent.term_id) left join relation on parent.term_id=relation.parent_term_id left join relation_type on (relation.relation_type_id=relation_type.relation_type_id and relation_type.name='regulates') left join term child on (child.term_id=relation.child_term_id) join ontology child_ontology on (child.ontology_id=child_ontology.ontology_id and child_ontology.name='GO') order by relation_type.name desc) t group by t.term_id order by t.parent_name;";
  my $sth = $dbc->prepare($sql);
  $sth->execute();
  
  # Returns an array reference for all rows.
  my $goslims = $sth->fetchall_arrayref();
  
  $sth->finish();
  
  print $callback . '( ' . $self->jsonify($goslims) . ' ) ';
  return $self;
}

1;
