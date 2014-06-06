package EnsEMBL::Web::Controller::SequenceDownload;

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
  
  my $hub       = new EnsEMBL::Web::Hub;
  my $species   = $hub->species;
  my $g         = $hub->param('g');
  my $utr       = $hub->param('utr');
  my $intron    = $hub->param('intron');
  my $flanking5 = $hub->param('flanking5');
  my $flanking3 = $hub->param('flanking3');
  my $callback  = $hub->param('callback');

  my $ga  = $hub->get_adaptor('get_GeneAdaptor');
  my $gene = $ga->fetch_by_stable_id($g);
  
  my @seq;
  
  if ($intron eq 'include') {
    my $start = 0;
    my $end = 0;
    if ($gene->strand == -1) {
      $start = $gene->seq_region_start() - $flanking3;
      $end = $gene->seq_region_end() + $flanking5;
    } else {
      $start = $gene->seq_region_start() - $flanking5;
      $end = $gene->seq_region_end() + $flanking3;
    }
    
    #if ($gene->strand == -1) {
    #  my $reverse = $end;
    #  $end = $start;
    #  $start = $reverse;
    #}
    
    if ($utr eq 'exclude') {
      my @transcripts = @{ $gene->get_all_Transcripts };
      foreach my $transcript (@transcripts) {
        if ($gene->strand == -1) {
          $start = $transcript->coding_region_start() - $flanking3;
          $end   = $transcript->coding_region_end() + $flanking5;
        } else {
          $start = $transcript->coding_region_start() - $flanking5;
          $end   = $transcript->coding_region_end() + $flanking3;
        }
        
        my $sa  = $hub->get_adaptor('get_SliceAdaptor');
        my $slice = $sa->fetch_by_region($gene->slice->coord_system_name,$gene->slice->seq_region_name,$start,$end);
        if ($gene->strand == -1) {
          $slice = $slice->invert();
        }
        push @seq, {name => $gene->stable_id, seq => $slice->seq(), test => '1', start => $start, end => $end};
      }
    } else {
      my $sa  = $hub->get_adaptor('get_SliceAdaptor');
      my $slice = $sa->fetch_by_region($gene->slice->coord_system_name,$gene->slice->seq_region_name,$start,$end);
      if ($gene->strand == -1) {
        $slice = $slice->invert();
      }
      push @seq, {name => $gene->stable_id, seq => $slice->seq(), test => '2', start => $start, end => $end, seq_region => $gene->slice->seq_region_name, coord_sys => $gene->slice->coord_system_name, seq_len => length($slice->seq())};
    }
    
  } else {
    my @transcript_seq;
    my @transcripts = @{ $gene->get_all_Transcripts };
    foreach my $transcript (@transcripts) {
      if ($utr eq 'include') {
        push @seq, {name => $transcript->stable_id, seq => $transcript->seq->seq(), test => '3', seq_len => length($transcript->seq->seq())};
      } elsif ($transcript->biotype eq 'protein_coding') {
        push @seq, {name => $transcript->stable_id, seq => $transcript->translateable_seq(), test => '4'};
      } else {
        push @seq, {name => $transcript->stable_id, seq => $transcript->seq->seq(), test => '5', seq_len => length($transcript->seq->seq())};
      }
    }
  }

  print $callback . '( ' . $self->jsonify(\@seq) . ' ) ';
  return $self;
}

1;
