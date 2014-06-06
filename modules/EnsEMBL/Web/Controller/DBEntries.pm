package EnsEMBL::Web::Controller::DBEntries;

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
  my $dba = $hub->get_adaptor('get_DBEntryAdaptor');
  my $gene = $ga->fetch_by_stable_id($query);
  my $dblinks = $gene->get_all_DBEntries();
  #my $dblinks = $dba->fetch_all_by_Gene($gene);
  
  my @entries = ();
  foreach my $dbentry (@{ $dblinks }) {
    if (ref $dbentry eq 'Bio::EnsEMBL::OntologyXref') {
      #print ref $dbentry;
      my @evidence = @{ $dbentry->get_all_linkage_info() };
      
      foreach my $evidencelink (@evidence) {
      #  print $evidencelink, ':', join(' ', @{ $evidencelink }), ' | ';
        my @el = @{ $evidencelink };
        my $evidence_id = $el[0];
        my $evidence_source = q{};
        if (scalar @el > 1) {
          $evidence_source = $el[1]->display_id;
          #print $el[1];
        }
        
        my @el = @{ $evidencelink };
        push @entries, {display_id      => $dbentry->display_id,
                        #description     => $dbentry->description,
                        dbname          => $dbentry->dbname,
                        evidence_id     => $evidence_id,
                        evidence_source => $evidence_source,
                        };
      }
    } else {
      #print ref $dbentry;
      push @entries, {display_id  => $dbentry->display_id,
                      #description => $dbentry->description,
                      dbname      => $dbentry->dbname,
                      type        => $dbentry->ensembl_object_type};
    }
  }
  
  print $callback . '( ' . $self->jsonify(\@entries) . ' ) ';
  return $self;
}

1;
