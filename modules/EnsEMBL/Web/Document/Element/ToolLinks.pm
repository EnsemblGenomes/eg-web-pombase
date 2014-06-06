package EnsEMBL::Web::Document::Element::ToolLinks;

### Generates links to site tools - BLAST, help, login, etc (currently in masthead)

use strict;

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  
  my $pbquery = 'last_gene';
  if ($hub->type == 'Gene' or $hub->type == 'Transcript') {
    my $pars = $hub->core_params;
    if ($pars->{'g'}) {
      $pbquery = $pars->{'g'};
    }
  }
  
  my $species = $hub->species;
     $species = !$species || $species eq 'Multi' || $species eq 'common' ? 'Multi' : $species;
  my @links; # = sprintf '<a class="constant" href="%s">Home</a>', $self->home;
###EG  
  #push @links, qq{<a class="constant" href="/$species/blastview">BLAST</a>} if $self->blast;
  #push @links,   '<a class="constant" href="/biomart/martview">BioMart</a>';
###
  
  #push @links,   '<a class="constant" id="pombase_link" href="http://www.pombase.org/spombe/result/'.$pbquery.'"><img src="/i/Back2GeneOverview.png" alt="Back to Gene Overview"></a>';
  push @links, '<FORM  METHOD="GET" ACTION="http://www.pombase.org/spombe/result/'.$pbquery.'"><INPUT TYPE="submit" VALUE="Gene Overview" /></FORM>';
  push @links, qq{<a class="constant" href="/$species/blastview">BLAST</a>} if $self->blast;
  push @links, qq{<a class="constant" href="http://blast.ncbi.nlm.nih.gov/Blast.cgi">NCBI BLAST</a>};
  push @links,   '<a class="constant" href="/tools.html">Tools</a>';
  push @links,   '<a class="constant" href="/downloads.html">Downloads</a>';
  push @links,   '<a class="constant" href="http://www.pombase.org/help">PomBase Help</a>';
  #push @links,   '<a class="constant" href="http://www.pombase.org/about/contacts/">Contact PomBase</a>';
  push @links,   '<a class="constant modal_link" href="/Help/Mirrors">Mirrors</a>' if keys %{$hub->species_defs->ENSEMBL_MIRRORS || {}};

  my $last  = pop @links;
  my $tools = join '', map "<li>$_</li>", @links;
  
  return qq{
    <ul class="tools">$tools<li class="last">$last</li></ul>
    <div class="more">
      <a href="#">More <span class="arrow">&#9660;</span></a>
    </div>
  };
}

1;

