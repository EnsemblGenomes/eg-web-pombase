package EnsEMBL::Web::Controller::GeneModels;

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
  my $query   = $hub->param('r');
  my $start   = $hub->param('s');
  my $end     = $hub->param('e');
  my $callback   = $hub->param('callback');
  my $sa = $hub->get_adaptor('get_SliceAdaptor');
  my $ga = $hub->get_adaptor('get_GeneAdaptor');
  my $slice = $sa->fetch_by_region('chromosome', $query, $start, $end);
  my @genes = @{ $ga->fetch_all_by_Slice($slice) };
  my @gm = ();
  my $results = "";
  foreach my $gene (@genes) {
    push @gm, {gene_id => $gene->display_xref->primary_id,
               name => $gene->display_xref->display_id,
               description => $gene->description,
               biotype => $gene->biotype,
               start => $gene->start,
               end => $gene->end};
  }
  #print @gm;
  print $callback . '( ' . $self->jsonify(\@gm) . ' ) ';
  return $self;
}

1;
