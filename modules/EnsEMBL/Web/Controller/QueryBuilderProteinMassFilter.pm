package EnsEMBL::Web::Controller::QueryBuilderProteinMassFilter;

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
  my $mass_min = $hub->param('m');
  my $mass_max = $hub->param('n');
  my $callback = $hub->param('callback');
  
  my $dbc = $hub->database('core')->dbc();
  my $sql = "select x.dbprimary_acc, tna.value from gene g, transcript ts, translation tn, translation_attrib tna, attrib_type at, xref x where ts.gene_id=g.gene_id and g.display_xref_id=x.xref_id and ts.transcript_id=tn.transcript_id and tn.translation_id=tna.translation_id and tna.attrib_type_id=at.attrib_type_id and at.code = 'MolecularWeight' and cast(tna.value AS DECIMAL) between ? and ?";
  my $sth = $dbc->prepare($sql);
  $sth->bind_param(1, $mass_min);
  $sth->bind_param(2, $mass_max);
  $sth->execute();
  
  # Returns an array reference for all rows.
  my $protein_mass = $sth->fetchall_arrayref();
  
  $sth->finish();
  
  print $callback . '( ' . $self->jsonify($protein_mass) . ' ) ';
  return $self;
}

1;
