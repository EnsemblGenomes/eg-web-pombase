package EnsEMBL::Web::Controller::ChromosomeModel;

### Provides JSON results for autocomplete dropdown in location navigation bar

use strict;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;
#use Data::Dumper;

use base qw(EnsEMBL::Web::Controller);

sub new {
  my $class = shift;
  my $self  = {};
  
  bless $self, $class;
  
  my $hub     = new EnsEMBL::Web::Hub;
  my $species = $hub->species;
  my $callback   = $hub->param('callback');
  
  my @chr_array = ();
  my $slice_adaptor = $hub->get_adaptor('get_SliceAdaptor');
  my $chr_slices = $slice_adaptor->fetch_all( 'chromosome' );

  my $sfa = $hub->get_adaptor('get_SimpleFeatureAdaptor');  
  foreach my $slice ( @{ $chr_slices } ) {
    my @centromeres = @{ $sfa->fetch_all_by_Slice($slice) };
    my @sfs = ();
    foreach my $sf (@centromeres) {
      if ($sf->display_label eq 'centromere') {
        push @sfs, {
            name  => $sf->display_label,
            start => $sf->seq_region_start,
            end => $sf->seq_region_end,
        };
      }
    }
    push @chr_array, {
        name             => $slice->seq_region_name,
        start            => $slice->start,
        end              => $slice->end,
        centromere       => \@sfs,
    };
    
  }
  
  #print @gm;
  print $callback . '( ' . $self->jsonify(\@chr_array) . ' ) ';
  return $self;
}

1;
