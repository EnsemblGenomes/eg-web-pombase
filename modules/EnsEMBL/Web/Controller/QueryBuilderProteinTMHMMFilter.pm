package EnsEMBL::Web::Controller::QueryBuilderProteinTMHMMFilter;

### Provides JSON results for protein TMHMM counts

use strict;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;

use base qw(EnsEMBL::Web::Controller);

sub new {
  my $class = shift;
  my $self  = {};
  
  bless $self, $class;
  
  my $hub      = new EnsEMBL::Web::Hub;
  my $count_min = $hub->param('m');
  my $count_max = $hub->param('n');
  my $callback = $hub->param('callback');
  
  

  my $dbc = $hub->database('core')->dbc();
  my $sql = "select gene.stable_id as s1, transcript.stable_id as s2, count(protein_feature.protein_feature_id) from gene join transcript on (gene.gene_id=transcript.gene_id) join translation on (transcript.transcript_id=translation.transcript_id) join protein_feature on (translation.translation_id=protein_feature.translation_id) join analysis on (protein_feature.analysis_id=analysis.analysis_id) where analysis.logic_name='tmhmm' group by gene.stable_id, transcript.stable_id having count(*) between ? AND ?";
  my $sth = $dbc->prepare($sql);
  $sth->bind_param(1, $count_min);
  $sth->bind_param(2, $count_max);
  $sth->execute();
  
  # Returns an array reference for all rows.
  my $protein_tm = $sth->fetchall_arrayref();
  
  $sth->finish();
  
  print $callback . '( ' . $self->jsonify($protein_tm) . ' ) ';
  return $self;
}

1;
