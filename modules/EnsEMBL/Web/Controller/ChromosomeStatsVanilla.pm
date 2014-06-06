package EnsEMBL::Web::Controller::ChromosomeStatsVanilla;

### Provides JSON results Chromosome Statistics

use strict;

use EnsEMBL::Web::Controller::SSI;
use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;

use base qw(EnsEMBL::Web::Controller);

sub new {
  my $class = shift;
  my $self  = {};
  
  bless $self, $class;
  
  my $hub     = new EnsEMBL::Web::Hub;
  my $species = $hub->species;
  my $query   = $hub->param('q');
  my $callback   = $hub->param('callback');

  my $file = '/ssi/species/stats_PomBase.txt';
  my $file_location = EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, $file);
  #warn $file_location;

  #open my ($fh), '<', $file_location or die;
  #my @lines = <$fh>;
  print $callback . '( ' . $file_location . ' ) ';
  
  return $self;
}

1;
