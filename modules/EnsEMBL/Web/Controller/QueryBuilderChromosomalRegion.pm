package EnsEMBL::Web::Controller::QueryBuilderChromosomalRegion;

### Provides JSON results for chromosomal regions

use strict;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;
use feature 'switch';

use base qw(EnsEMBL::Web::Controller);

sub new {
  my $class = shift;
  my $self  = {};
  
  bless $self, $class;
  
  my $hub      = new EnsEMBL::Web::Hub;
  my $region   = $hub->param('r');
  my $callback = $hub->param('callback');
  
  my $region_transition = q{};
  
  given ($region) {
    when('centromere') {
      $region = 'centromere';
    }
    when('centromere-L') {
      $region = 'centromere';
      $region_transition = 'left';
    }
    when('centromere-R') {
      $region = 'centromere';
      $region_transition = 'right';
    }
    when('mtr') {
      $region = 'mating_type_region';
    }
    when('mtr-L') {
      $region = 'mating_type_region';
      $region_transition = 'left';
    }
    when('mtr-R') {
      $region = 'mating_type_region';
      $region_transition = 'right';
    }
  }
 
  my $sa  = $hub->get_adaptor('get_SliceAdaptor');
  my $sfa  = $hub->get_adaptor('get_SimpleFeatureAdaptor');
  
  my @seq_features = @{ $sfa->fetch_all() };
  
  my @seq_genes = ();
  foreach my $sf (@seq_features) {
    if ($sf->display_label eq $region) {
      my $slice = q{};
      if ($region_transition eq 'left') {
        $slice = $sa->fetch_by_region($sf->slice->coord_system_name, $sf->slice->seq_region_name, 1, $sf->start);
      } elsif ($region_transition eq 'right') {
        $slice = $sa->fetch_by_region($sf->slice->coord_system_name, $sf->slice->seq_region_name, $sf->end, $sf->slice->end);
      } else {
        $slice = $sa->fetch_by_region($sf->slice->coord_system_name, $sf->slice->seq_region_name, $sf->start, $sf->end);
      }
      
      my @sf_genes = @{ $slice->get_all_Genes() };
      foreach my $sfg (@sf_genes) {
        push @seq_genes, $sfg->stable_id;
      }
    }
    # print $sf->display_label . "\n";
  }
  
  print $callback . '( ' . $self->jsonify(\@seq_genes) . ' ) ';
  return $self;
}

1;
