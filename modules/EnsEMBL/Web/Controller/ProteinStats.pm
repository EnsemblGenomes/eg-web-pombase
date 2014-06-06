package EnsEMBL::Web::Controller::ProteinStats;

### Provides JSON results for autocomplete dropdown in location navigation bar

use strict;

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
  
  my $ga = $hub->get_adaptor('get_GeneAdaptor');
  my $gene = $ga->fetch_by_stable_id($query);
  my $transcripts = $gene->get_all_Transcripts();
  
  my %tr = ();
  foreach my $transcript (@{ $transcripts }) {
    my $attributeAdaptor = $hub->get_adaptor('get_AttributeAdaptor');
    my $attributes = $attributeAdaptor->fetch_all_by_Translation($transcript->translation());
    my @stats_to_show = ();
    foreach my $stat (sort {$a->name cmp $b->name} @{$attributes}) {
      push @stats_to_show, {name=>$stat->name, value=>$stat->value};
    }
    $tr{$transcript->stable_id} = \@stats_to_show;
  }
  
  print $callback . '( ' . $self->jsonify(\%tr) . ' ) ';
  return $self;
}

1;
