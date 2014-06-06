package EnsEMBL::Web::Controller::GeneDataset;

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
  my @gene_DBentries = @{ $gene->get_all_DBEntries() };
  my @gm = ();
  
  push @gm, {type        => "Gene",
             gene_id     => $gene->stable_id,
             start       => $gene->start,
             end         => $gene->end,
             strand      => $gene->strand,
             name        => $gene->display_xref->display_id,
             description => $gene->description,
             biotype     => $gene->biotype};
  
  foreach my $dbentry (@gene_DBentries) {
    push @gm, {type        => "DBEntry_Gene",
               primary_id  => $dbentry->primary_id,
               dbname      => $dbentry->dbname,
               name        => $dbentry->display_id,
               description => $dbentry->description};
  }
  
  my @exons = @{ $gene->get_all_Exons };
  my @transcripts = @{ $gene->get_all_Transcripts };
  
  foreach my $exon (@exons) {
    push @gm, {type    => "Exon",
               exon_id => $exon->stable_id,
               start   => $exon->start,
               end     => $exon->end,
               strand  => $exon->strand};
    my @exon_DBentries = @{ $exon->get_all_DBEntries() };
    foreach my $dbentry (@exon_DBentries) {
      push @gm, {type        => "DBEntry_Exon",
                 primary_id  => $dbentry->primary_id,
                 dbname      => $dbentry->dbname,
                 name        => $dbentry->display_id,
                 description => $dbentry->description};
    }
  }
  
  foreach my $transcript (@transcripts) {
    push @gm, {type          => "Transcript",
               transcript_id => $transcript->stable_id->primary_id,
               start         => $transcript->start,
               end           => $transcript->end};
    my @transcript_DBentries = @{ $transcript->get_all_DBEntries() };
    foreach my $dbentry (@transcript_DBentries) {
      push @gm, {type        => "DBEntry_Transcript",
                 primary_id  => $dbentry->primary_id,
                 dbname      => $dbentry->dbname,
                 name        => $dbentry->display_id,
                 description => $dbentry->description};
    }
  }
  
  #print @gm;
  print $callback . '( ' . $self->jsonify(\@gm) . ' ) ';
  return $self;
}

1;
