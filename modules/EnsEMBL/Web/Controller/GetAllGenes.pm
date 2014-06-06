package EnsEMBL::Web::Controller::GetAllGenes;

### Provides JSON results for autocomplete dropdown in location navigation bar

use strict;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;
# use Data::Dumper;

use base qw(EnsEMBL::Web::Controller);

sub new {
  my $class = shift;
  my $self  = {};
  
  bless $self, $class;
  
  my $hub      = new EnsEMBL::Web::Hub;
  my $species  = $hub->species;
  my $callback = $hub->param('callback');
  
  my $ga  = $hub->get_adaptor('get_GeneAdaptor');
  my $sa  = $hub->get_adaptor('get_SliceAdaptor');
  
  my $chr_slices = $sa->fetch_all( 'chromosome' );
  my @gene_stable_ids = ();
  
  foreach my $slice ( @{ $chr_slices } ) {
    my @genes = @{ $ga->fetch_all_by_Slice($slice) };
    foreach my $gene ( @genes ) {
      push @gene_stable_ids, $gene->stable_id;
    }
  }
  
  print $callback . '( ' . $self->jsonify(\@gene_stable_ids) . ' ) ';
  return $self;
  
}
1;
