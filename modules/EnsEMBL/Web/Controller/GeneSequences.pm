package EnsEMBL::Web::Controller::GeneSequences;

### Provides JSON results for autocomplete dropdown in location navigation bar

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
  my $query    = $hub->param('q');
  my $callback = $hub->param('callback');
  
  my $ga  = $hub->get_adaptor('get_GeneAdaptor');
  
  my $gene = $ga->fetch_by_stable_id($query);
  
  my @seq;
  push @seq, {type => 'gene', name => $gene->stable_id, seq => $gene->seq()};
  
  my @transcripts = @{ $gene->get_all_Transcripts };
  
  my @transcript_seq;
  foreach my $transcript (@transcripts) {
    push @seq, {type => 'cDNA', name => $transcript->stable_id, seq => $transcript->translateable_seq()};
    if ($gene->biotype eq 'protein_coding') {
      push @seq, {type => 'protein', name => $transcript->stable_id, seq => $transcript->translation->seq()};
    }
  }
  
  print $callback . '( ' . $self->jsonify(\@seq) . ' ) ';
  return $self;
}

1;
