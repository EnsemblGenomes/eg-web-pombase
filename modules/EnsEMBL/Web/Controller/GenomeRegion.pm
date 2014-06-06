package EnsEMBL::Web::Controller::GenomeRegion;

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
    my @gene = {gene_id     => $gene->display_xref->primary_id,
                name        => $gene->display_xref->display_id,
                description => $gene->description,
                biotype     => $gene->biotype,
                start       => $gene->seq_region_start,
                stop        => $gene->seq_region_end,
                status      => $gene->status,
                strand      => $gene->strand,};
    
    my @transcripts = ();
    foreach my $transcript ( @{ $gene->get_all_Transcripts } ) {
      my @exons = ();
      foreach my $exon ( @{ $transcript->get_all_Exons() } ) {
        push @exons, {
                        start => $exon->seq_region_start,
                        stop  => $exon->seq_region_end,
                     };
      }
      if ($transcript->translation()) {
        my @translation = {
                            start => $transcript->coding_region_start,
                            stop  => $transcript->coding_region_end
                          };
        
        push @transcripts, {
                                exons       => \@exons,
                                translation => \@translation
                           };
      } else {
        my @translation = ();
        
        push @transcripts, {
                                exons       => \@exons,
                                translation => \@translation
                           }
      }
    }
    
    push @gm, {gene => \@gene, transcripts => \@transcripts};
  }
  
  print $callback . '( ' . $self->jsonify(\@gm) . ' ) ';
  return $self;
}

1;
