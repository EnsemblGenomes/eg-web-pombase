package EnsEMBL::Web::Controller::GenomeSequence;

### Provides FASTA genome slice

use strict;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;

use base qw(EnsEMBL::Web::Controller);

sub new {
  my $class = shift;
  my $self  = {};
  
  bless $self, $class;
  
  my $hub      = new EnsEMBL::Web::Hub;
  my $species  = $hub->species;
  my $chr      = $hub->param('c');
  my $start    = $hub->param('s');
  my $end      = $hub->param('e');
  my $callback = $hub->param('callback');
  
  my $sa  = $hub->get_adaptor('get_SliceAdaptor');
  
  my $slice = $sa->fetch_by_region('chromosome', $chr, $start, $end);
  
  my @seq;
  push @seq, $slice->seq();
  
  print $callback . '( ' . $self->jsonify(\@seq) . ' ) ';
  return $self;
}

1;
