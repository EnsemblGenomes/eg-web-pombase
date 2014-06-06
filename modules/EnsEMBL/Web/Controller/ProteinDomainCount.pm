package EnsEMBL::Web::Controller::ProteinDomainCount;

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
  my $prot_domain = $hub->param('q');
  my $callback = $hub->param('callback');
  
  my $dbc = $hub->database('core')->dbc();
  my $sql = "select distinct g.stable_id, IFNULL(gd.display_label, g.stable_id) as display_label, g.description, g.biotype, a.logic_name, tl.stable_id, interpro.interpro_ac from gene g join transcript tc on (g.gene_id=tc.gene_id) join translation tl on (tc.transcript_id=tl.transcript_id) join protein_feature pf on (tl.translation_id=pf.translation_id) join analysis a on (pf.analysis_id=a.analysis_id) left join xref gd on (g.display_xref_id=gd.xref_id) left join interpro on (pf.hit_name=interpro.id) where pf.hit_name = ?";
  my $sth = $dbc->prepare($sql);
  $sth->bind_param(1, $prot_domain);
  $sth->execute();
  
  # Returns an array reference for all rows.
  my $protein_domains = $sth->fetchall_arrayref();
  $sth->finish();
  
  print $callback . '( ' . $self->jsonify($protein_domains) . ' ) ';
  return $self;
}

1;
