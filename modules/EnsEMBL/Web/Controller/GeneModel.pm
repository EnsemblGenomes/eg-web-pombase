package EnsEMBL::Web::Controller::GeneModel;

### Provides JSON results for autocomplete dropdown in location navigation bar

use strict;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;
# use Data::Dumper;

use base qw(EnsEMBL::Web::Controller);

sub new {
  my $class = shift;
  my $self  = {};
  
  bless $self, $class;
  
  my $hub     = new EnsEMBL::Web::Hub;
  my $species = $hub->species;
  my $query   = $hub->param('q');
  my $callback   = $hub->param('callback');
  
  my $mc  = $hub->get_adaptor('get_MetaContainer');
  my $ga  = $hub->get_adaptor('get_GeneAdaptor');
  my $sa  = $hub->get_adaptor('get_SliceAdaptor');
  my $csa = $hub->get_adaptor('get_CoordSystemAdaptor');
  my $poa = $hub->get_databases('go')->{'go'}->get_OntologyTermAdaptor;
  my $goa = $hub->get_databases('go')->{'go'}->get_GOTermAdaptor;
  
  my $gene = $ga->fetch_by_stable_id($query);
  my @gene_DBentries = @{ $gene->get_all_DBEntries() };
  my @gm = ();
  
  my @release = @{ $mc->list_value_by_key('annotation.release') };
  my @source  = @{ $mc->list_value_by_key('annotation.source') };
  my @date    = @{ $mc->list_value_by_key('annotation.date') };
  
  push @gm, { type    => 'meta',
              release => $release[0],
              source  => $source[0],
              date    => $date[0]};
  
  my @contigs = @{ $gene->slice->project('contig') };
  
  my %interactions;
  
  my $centre_slice = int((($gene->end-$gene->start)/2)+$gene->start);
  my $larger_slice = $sa->fetch_by_region($gene->slice->coord_system_name,$gene->slice->seq_region_name,$centre_slice-7500,$centre_slice+7500);
  
  my @genes_in_slice = @{ $larger_slice->get_all_Genes };
  my @neighbouring_genes = ();
  foreach my $gene_in_slice (@genes_in_slice) {
    my $neighbour_name = '';
    if (defined $gene_in_slice->display_xref) {
      $neighbour_name = $gene_in_slice->display_xref->display_id;
    }
    push @neighbouring_genes, {gene_id => $gene_in_slice->stable_id,
                               name    => $neighbour_name};
  }
  
  my $gene_name = $gene->stable_id;
  if (defined $gene->display_xref) {
    $gene_name = $gene->display_xref->display_id;
  }
  push @gm, {type        => "Gene",
             gene_id     => $gene->stable_id,
             start       => $gene->start,
             end         => $gene->end,
             chromosome  => $gene->slice->seq_region_name,
             contig      => $contigs[0]->to_Slice()->seq_region_name,
             strand      => $gene->strand,
             name        => $gene_name,
             description => $gene->description,
             biotype     => $gene->biotype,
             status      => $gene->status,
             species     => $species,
             neighbours  => \@neighbouring_genes};
  
  foreach my $dbentry (@gene_DBentries) {
    
    my $dbc = $hub->database('core')->dbc();
    my $sql = "SELECT * FROM dependent_xref WHERE dependent_xref_id = ?;";
    my $sth = $dbc->prepare($sql);
    $sth->bind_param(1, $dbentry->dbID);
    $sth->execute();
    
    # Returns an array reference for all rows.
    my $dependent_xref = $sth->fetchall_arrayref();
    $sth->finish();
    
    if (ref $dbentry eq 'Bio::EnsEMBL::OntologyXref') {
      my @evidence = @{ $dbentry->get_all_linkage_info() };
      foreach my $evidencelink (@evidence) {
        my @el = @{ $evidencelink };
        my $evidence_id = $el[0];
        my $evidence_source   = q{};
        my $evidence_desc     = q{};
        my $evidence_dbname   = q{};
        my $evidence_info_text = q{};
        if (scalar @el > 1) {
          $evidence_source    = $el[1]->display_id;
          $evidence_desc      = $el[1]->description;
          $evidence_dbname    = $el[1]->dbname;
          $evidence_info_text = $el[1]->info_text;
        }
        
        my $term = q{};
        if ($dbentry->dbname == 'GO') {
          $term = $goa->fetch_by_accession($dbentry->primary_id);
        } else {
          $term = $poa->fetch_by_accession($dbentry->primary_id);
        }
        
        my $associated_xref = {};
        my $annot_ext = $dbentry->get_all_associated_xrefs();
        
        foreach my $ax_group (sort keys %{ $annot_ext }) {
          my $group = $annot_ext->{$ax_group};
          foreach my $ax_rank (sort keys %{ $group }) {
            my @ax = @{ $group->{$ax_rank} };
            my $name = $ax[0]->primary_id;
            if (
              $ax[0]->dbname eq 'PomBase_Systematic_ID' or
              $ax[0]->dbname eq 'PomBase_TRANSCRIPT' or
              $ax[0]->dbname eq 'PomBase'
            ) {
              my $ax_gene = $ga->fetch_by_stable_id($ax[0]->primary_id);
              $name = $ax_gene->display_xref->display_id;
            }
            $associated_xref->{$ax_group}->{$ax_rank} = {
                condition_type   => $ax[2],
                primary_id       => $ax[0]->primary_id,
                name             => $name,
                dbname           => $ax[0]->dbname,
                accession        => $ax[0]->display_id,
                description      => $ax[0]->description,
                #name             => $ax[0]->name,
                ontology         => $ax[0]->ontology,
                source_accession => $ax[1]->display_id,
                source_dbname    => $ax[1]->dbname,
                source_name      => $ax[1]->name,
                source_ontology  => $ax[1]->ontology,
            }
          }
        }
        
        # my @el = @{ $evidencelink };
        push @gm, {type               => "Gene_DBEntry_Ontology",
                   primary_id         => $dbentry->primary_id,
                   #description        => $dbentry->description,
                   dbname             => $dbentry->dbname,
                   accession          => $dbentry->display_id,
                   name               => $term->name,
                   aspect             => $term->namespace,
                   ontology           => $term->ontology,
                   linkage_annotation => $dbentry->linkage_annotation,
                   evidence_id        => $evidence_id,
                   evidence_source    => $evidence_source,
                   evidence_desc      => $evidence_desc,
                   evidence_dbname    => $evidence_dbname,
                   evidence_name      => $self->_get_feature_name($evidence_dbname, $evidence_source),  #######
                   evidence_info_text => $evidence_info_text,
                   associated_xref    => $associated_xref,
                  };
      }
    } elsif ($dbentry->dbname eq "PomBase_Interaction_GENETIC" or $dbentry->dbname eq "PomBase_Interaction_PHYSICAL") {
      
      my $interactor_gene = $ga->fetch_by_stable_id($dbentry->display_id);
      my $DBEntry_dep = $dbentry->get_all_dependents();
      my %dep;
      my %interactor;
      
      if (defined $interactions{$dbentry->dbname}{$interactor_gene->display_id}) {
        %interactor = %{ $interactions{$dbentry->dbname}{$interactor_gene->display_id} };
        %dep = %{ $interactor{'evidence'} };
      } else {
        %interactor = (type        => "Gene_DBEntry",
                   primary_id  => $dbentry->primary_id,
                   #dbname      => $dbentry->dbname,
                   gene_id     => $dbentry->display_id,
                   name        => $interactor_gene->display_xref->display_id,
                   description => $interactor_gene->description,);
      }
      
      foreach my $d (@{$DBEntry_dep}) {
        if (!defined $dep{$d->display_id}) {
          my @linkage = ($dbentry->linkage_annotation);
          $dep{$d->display_id} = \@linkage;
        } else {
          my @linkage = @{ $dep{$d->display_id} };
          push @linkage, ($dbentry->linkage_annotation);
          $dep{$d->display_id} = \@linkage;
        }
      }
      $interactor{'evidence'}       = \%dep;
      
      $interactions{$dbentry->dbname}{$interactor_gene->display_id} = \%interactor;
      
    } elsif (scalar @{$dependent_xref} == 0) {
      push @gm, {type        => "Gene_DBEntry",
                 primary_id  => $dbentry->primary_id,
                 dbname      => $dbentry->dbname,
                 name        => $dbentry->display_id,
                 description => $dbentry->description,
                 synonyms    => $dbentry->get_all_synonyms,
                 info_text   => $dbentry->info_text};
    }
  }
  
  push @gm, {type  => 'InteractionSet',
             data  => \%interactions};
  
  my @exons = @{ $gene->get_all_Exons };
  my @transcripts = @{ $gene->get_all_Transcripts };
  
  foreach my $exon (@exons) {
    push @gm, {type    => "Exon",
               exon_id => $exon->stable_id,
               start   => $exon->start,
               end     => $exon->end,
               strand  => $exon->strand};
  }
  
  
  foreach my $transcript (@transcripts) {
    my $attributeAdaptor = $hub->get_adaptor('get_AttributeAdaptor');
    my @stats_to_show = ();
    my @protein_features_to_show = ();
    if ($transcript->translation()) { 
      my $attributes = $attributeAdaptor->fetch_all_by_Translation($transcript->translation());
      foreach my $stat (sort {$a->name cmp $b->name} @{$attributes}) {
        push @stats_to_show, {name=>$stat->name, value=>$stat->value};
      }
      my $translation = $transcript->translation();
      my @translation_features = @{ $translation->get_all_ProteinFeatures() };
      my $dbc = $hub->database('core')->dbc();
      my $sql = "select count(distinct translation_id) from protein_feature where hit_name = ?";
      foreach my $pf (@translation_features) {
        my $sth = $dbc->prepare($sql);
        $sth->bind_param(1, $pf->display_id);
        $sth->execute();
        
        # Returns an array reference for all rows.
        my @prot_dom_count = @{ $sth->fetchall_arrayref() };
        $sth->finish();
        push @protein_features_to_show, {name  => $pf->display_id,
                                         start => $pf->start,
                                         end   => $pf->end,
                                         score => $pf->score,
                                         source => $pf->analysis->logic_name,
                                         interpro => $pf->interpro_ac(),
                                         count => $prot_dom_count[0][0]};
      }
      push @gm, {type            => "Transcript",
                   transcript_id   => $transcript->stable_id,
                   start           => $transcript->start,
                   end             => $transcript->end,
                   cds_start       => $transcript->coding_region_start,
                   cds_end         => $transcript->coding_region_end,
                   proteinstats    => \@stats_to_show,
                   proteinfeatures => \@protein_features_to_show};
    } else {
        push @gm, {type            => "Transcript",
                   transcript_id   => $transcript->stable_id,
                   start           => $transcript->start,
                   end             => $transcript->end,
                   proteinstats    => \@stats_to_show,
                   proteinfeatures => \@protein_features_to_show};
   }
    #my @transcript_DBentries = @{ $transcript->get_all_DBLinks() };
    my @transcript_DBentries = @{ $transcript->get_all_DBLinks() };
    foreach my $dbentry (@transcript_DBentries) {
      if (ref $dbentry eq 'Bio::EnsEMBL::OntologyXref') {
        #if ($dbentry->primary_id eq 'FYPO:0000087') {
        #  print Data::Dumper->Dump([$dbentry->get_all_associated_xrefs()]);
        #  print Data::Dumper->Dump([$dbentry->get_extensions()]);
        #}
        my @evidence = @{ $dbentry->get_all_linkage_info() };
        foreach my $evidencelink (@evidence) {
          my @el = @{ $evidencelink };
          my $evidence_id = $el[0];
          my $evidence_source   = q{};
          my $evidence_desc     = q{};
          my $evidence_dbname   = q{};
          my $evidence_info_text = q{};
          if (scalar @el > 1) {
            $evidence_source    = $el[1]->display_id;
            $evidence_desc      = $el[1]->description;
            $evidence_dbname    = $el[1]->dbname;
            $evidence_info_text = $el[1]->info_text;
          }
          
          my $term = q{};
          if ($dbentry->dbname == 'GO') {
            $term = $goa->fetch_by_accession($dbentry->primary_id);
          } else {
            $term = $poa->fetch_by_accession($dbentry->primary_id);
          }
          
          my $associated_xref = {};
          my $annot_ext = $dbentry->get_all_associated_xrefs();
          
          #print "\t" . $dbentry->primary_id . "\n";
          foreach my $ax_group (sort keys %{ $annot_ext }) {
            my $group = $annot_ext->{$ax_group};
            #print Data::Dumper->Dump([$group]);
            foreach my $ax_rank (sort keys %{ $group }) {
              my @ax = @{ $group->{$ax_rank} };
              #print $ax[0] . "\t" . $ax[1] . "\t" . $ax[2] . "\n";
              if (defined $ax[0]) {
                  my $name = $ax[0]->primary_id;
                  if (
                    $ax[0]->dbname eq 'PomBase_Systematic_ID' or
                    $ax[0]->dbname eq 'PomBase_TRANSCRIPT' or 
                    $ax[0]->dbname eq 'PomBase'
                  ) {
                    my $ax_gene = $ga->fetch_by_stable_id($ax[0]->primary_id);
                    if ( defined($ax_gene) ) {
                      $name = $ax_gene->display_xref->display_id;
                    }
                  }
                  #print "\t\t" . $ax_group;
                  #print "\t" . $ax_rank;
                  #print "\t" . $ax[0]->primary_id;
                  #print "\t" . $ax[1]->primary_id;
                  #print "\t" . $ax[2] . "\n";
                  #print "\t" . $ax[2] . "\t" . $ax[0]->display_id . "\n";
                  $associated_xref->{$ax_group}->{$ax_rank} = {
                      condition_type   => $ax[2],
                      primary_id       => $ax[0]->primary_id || q{},
                      name             => $name || q{},
                      dbname           => $ax[0]->dbname || q{},
                      accession        => $ax[0]->display_id || q{},
                      description      => $ax[0]->description || q{},
                      #name             => $ax[0]->name || '',
                      #ontology         => $ax[0]->ontology || '',
                      source_accession => $ax[1]->display_id,
                      source_dbname    => $ax[1]->dbname,
                      info_text        => $ax[0]->info_text,
                      #source_name      => $ax[1]->name,
                      #source_ontology  => $ax[1]->ontology,
                  }
              } else {
                $associated_xref->{$ax_group}->{$ax_rank} = {
                      condition_type   => $ax[2],
                      primary_id       => q{},
                      name             => q{},
                      dbname           => q{},
                      accession        => q{},
                      description      => q{},
                      display_label    => q{},
                      source_accession => $ax[1]->display_id,
                      source_dbname    => $ax[1]->dbname,
                }
              }
            }
          }
            
          # my @el = @{ $evidencelink };
          push @gm, {type               => "Transcript_DBEntry_Ontology",
                     transcript_id      => $transcript->stable_id,
                     primary_id         => $dbentry->primary_id,
                     #description        => $dbentry->description,
                     dbname             => $dbentry->dbname,
                     accession          => $dbentry->display_id,
                     name               => $term->name,
                     aspect             => $term->namespace,
                     ontology           => $term->ontology,
                     linkage_annotation => $dbentry->linkage_annotation,
                     evidence_id        => $evidence_id,
                     evidence_source    => $evidence_source,
                     evidence_desc      => $evidence_desc,
                     evidence_dbname    => $evidence_dbname,
                     evidence_name      => $self->_get_feature_name($evidence_dbname, $evidence_source),  #####
                     evidence_info_text => $evidence_info_text,
                     associated_xref    => $associated_xref,
                    };
        }
      } else {
        push @gm, {type        => "Transcript_DBEntry",
                   primary_id  => $dbentry->primary_id,
                   dbname      => $dbentry->dbname,
                   name        => $dbentry->display_id,
                   description => $dbentry->description};
      }
    }
  }
  
  #print @gm;
  print $callback . '( ' . $self->jsonify(\@gm) . ' ) ';
  return $self;
}

sub _get_feature_name {
  #my $class = shift;
  my ($self, $dbname, $query)  = @_;
  #bless $self, $class;
  my $hub     = new EnsEMBL::Web::Hub;
  
  my @query_split = split(m/:/ms, $query);
  
  if ( scalar @query_split < 2 ) {
    if ( $dbname eq 'PomBase_GENE' ) {
      my $ga  = $hub->get_adaptor('get_GeneAdaptor');
      my $gene = $ga->fetch_by_stable_id($query);
      return $gene->display_xref->display_id;
    }
  } else {
    # warn $query;
    if ($query_split[0] eq 'GeneDB_Spombe' or $query_split[0] eq 'PomBase_GENE' or $query_split[0] eq 'PomBase_GENE') {
      my $ga  = $hub->get_adaptor('get_GeneAdaptor');
      my $gene = $ga->fetch_by_stable_id($query_split[1]);
      if ( defined $gene ) {
        return $gene->display_xref->display_id;
      } else {
        return '<del>' . $query_split[1] . '</del>';
      }
    }
  }
}

1;
