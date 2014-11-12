package EnsEMBL::Web::ImageConfig::contigviewbottom;

use strict;

sub init {
  my $self = shift;
  
  $self->set_parameters({
    toolbars        => { top => 1, bottom => 1 },
    sortable_tracks => 'drag', # allow the user to reorder tracks on the image
    datahubs        => 1,      # allow datahubs
    opt_halfheight  => 0,      # glyphs are half-height [ probably removed when this becomes a track config ]
    opt_lines       => 1,      # draw registry lines
  });
  
  # First add menus in the order you want them for this display
  $self->create_menus(qw(
    sequence
    marker
    trans_associated
    transcript
    prediction
    dna_align_cdna
    dna_align_est
    dna_align_rna
    dna_align_other
    protein_align
    protein_feature
    rnaseq
    ditag
    simple
    genome_attribs
    misc_feature
    variation
    recombination
    somatic
    functional
    multiple_align
    conservation
    pairwise_blastz
    pairwise_tblat
    pairwise_other
    oligo
    repeat
    external_data
    user_data
    decorations
    information
  ));
  
  $self->image_resize = 1;
  my %desc = (
    contig    => 'Track showing underlying assembly contigs.',
    seq       => 'Track showing sequence in both directions. Only displayed at 1Kb and below.',
    codon_seq => 'Track showing 6-frame translation of sequence. Only displayed at 500bp and below.',
    codons    => 'Track indicating locations of start and stop codons in region. Only displayed at 50Kb and below.'
  );
  
  # Note these tracks get added before the "auto-loaded tracks" get added
  $self->add_tracks('sequence', 
    [ 'contig',    'Contigs',             'contig',   { display => 'normal', strand => 'r', description => $desc{'contig'}                                                                }],
    [ 'seq',       'Sequence',            'sequence', { display => 'normal', strand => 'b', description => $desc{'seq'},       colourset => 'seq',      threshold => 1,   depth => 1      }],
    [ 'codon_seq', 'Translated sequence', 'codonseq', { display => 'off',    strand => 'b', description => $desc{'codon_seq'}, colourset => 'codonseq', threshold => 0.5, bump_width => 0 }],
    [ 'codons',    'Start/stop codons',   'codons',   { display => 'off',    strand => 'b', description => $desc{'codons'},    colourset => 'codons',   threshold => 50                   }],
    [ 'blast',     'BLAT/BLAST hits',     '_blast',   { display => 'normal', strand => 'b',                                    colourset => 'feature',  sub_type => 'blast', menu => 'no' }]
  );
  
  $self->add_track('decorations', 'gc_plot', '%GC', 'gcplot', { display => 'normal',  strand => 'r', description => 'Shows percentage of Gs & Cs in region', sortable => 1 });
  
  if ($self->species_defs->ALTERNATIVE_ASSEMBLIES) {
    foreach my $alt_assembly (@{$self->species_defs->ALTERNATIVE_ASSEMBLIES}) {
      $self->add_track('misc_feature', "${alt_assembly}_assembly", "$alt_assembly assembly", 'alternative_assembly', { 
        display       => 'off', 
        strand        => 'f', 
        colourset     => 'alternative_assembly', 
        description   => "Track indicating $alt_assembly assembly", 
        assembly_name => $alt_assembly 
      });
    }
  }
  
  # show versions of clones from other sites
  if ($self->species_defs->das_VEGACLONES) {
    $self->add_track('misc_feature', 'v_clones', 'Vega clones', 'alternative_clones', {
      display     => 'off', 
      strand      => 'f', 
      description => 'Vega clones', 
      colourset   => 'alternative_clones', 
      das_source  => 'das_VEGACLONES'
    });
  }
  
  if ($self->species_defs->das_ENSEMBLCLONES) {
    $self->add_track('misc_feature', 'e_clones', 'Ensembl clones', 'alternative_clones', {
      display     => 'off', 
      strand      => 'f', 
      description => 'Ensembl clones', 
      colourset   => 'alternative_clones', 
      das_source  => 'das_ENSEMBLCLONES'
    });
  }
  
  # Add in additional tracks
  $self->load_tracks;
  $self->load_configured_das;
#  $self->load_configured_bigwig;
  $self->load_configured_bigbed;
#  $self->load_configured_bam;
  
  # These tracks get added after the "auto-loaded tracks get addded
  if ($self->species_defs->ENSEMBL_MOD) {
    $self->add_track('information', 'mod', '', 'text', {
      name    => 'Message of the day',
      display => 'normal',
      menu    => 'no',
      strand  => 'r', 
      text    => $self->species_defs->ENSEMBL_MOD
    });
  }

  $self->add_tracks('information',
    [ 'missing', '', 'text', { display => 'normal', strand => 'r', name => 'Disabled track summary', description => 'Show counts of number of tracks turned off by the user' }],
    [ 'info',    '', 'text', { display => 'normal', strand => 'r', name => 'Information',            description => 'Details of the region shown in the image' }]
  );
  
  $self->add_tracks('decorations',
    [ 'scalebar',  '', 'scalebar',  { display => 'normal', strand => 'b', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',     '', 'ruler',     { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }],
    [ 'draggable', '', 'draggable', { display => 'normal', strand => 'b', menu => 'no' }]
  );

  ## Switch on multiple alignments defined in MULTI.ini
  my $compara_db      = $self->hub->database('compara');
  if ($compara_db) {
    my $mlss_adaptor    = $compara_db->get_adaptor('MethodLinkSpeciesSet');
    my %alignments      = $self->species_defs->multiX('COMPARA_DEFAULT_ALIGNMENTS');
    while (my ($species_set, $method) = each (%alignments)) {
      my $mlss = $mlss_adaptor->fetch_by_method_link_type_species_set_name($method, $species_set);
      if ($mlss) {
        $self->modify_configs(
          [ 'alignment_compara_'.$mlss->dbID.'_constrained' ],
          { display => 'compact' }
        );
      }
    }
  }

  my @feature_sets = ('cisRED', 'VISTA', 'miRanda', 'NestedMICA', 'REDfly CRM', 'REDfly TFBS');
  
  foreach my $f_set (@feature_sets) {
    $self->modify_configs(
      [ "regulatory_regions_funcgen_$f_set" ],
      { depth => 25, height => 6 }
    );
  }
  
  # Enable cell line displays 
  my @cell_lines = sort keys %{$self->species_defs->databases->{'DATABASE_FUNCGEN'}->{'tables'}{'cell_type'}{'ids'}};
  
  foreach my $cell_line (@cell_lines) {
    $cell_line =~ s/:\w*//;
    
    # Turn off segmentation track
    $self->modify_configs(
      [ "seg_$cell_line"],
      { display => 'off' }
    );
  }
}

sub modify {
  my $self = shift;
  
  my $gene_transcript_menu = $self->tree->get_node('gene_transcript');
  
  # create pombase menus
  my $pombase_menu_binding = $self->create_submenu('chromatin_binding', 'Chromatin binding');
  $gene_transcript_menu->after($pombase_menu_binding);

  my $pombase_menu_binding = $self->create_submenu('intron_branch_point', 'Intron Branch Point');
  $gene_transcript_menu->after($pombase_menu_binding);
  
  my $pombase_menu_polya   = $self->create_submenu('polya_sites', 'Polyadenylation sites');
  $gene_transcript_menu->after($pombase_menu_polya);
  
  my $pombase_menu_reppro   = $self->create_submenu('replication_profiling', 'Replication Profiling');
  $gene_transcript_menu->after($pombase_menu_reppro);
  
  my $pombase_menu_reppro   = $self->create_submenu('regulatory_elements', 'Regulatory Elements');
  $gene_transcript_menu->after($pombase_menu_reppro);
  
  my $pombase_menu_transcriptome   = $self->create_submenu('transcriptome', 'Transcriptome');
  $gene_transcript_menu->after($pombase_menu_transcriptome);
  
  my $pombase_menu_nucleosome   = $self->create_submenu('nucleosome', 'Nucleosome Positioning');
  $gene_transcript_menu->after($pombase_menu_nucleosome);
  
  $self->load_configured_bam;
  $self->load_configured_bed;
  $self->load_configured_bedgraph;
  $self->load_configured_bigwig;
}

1;
