package EnsEMBL::Web::Document::Element::Logo;

use strict;

sub content {
  my $self = shift;
  my $url = $self->href || $self->home_url;
#  return sprintf( '%s<a href="%s">%s</a>%s%s',
#    $self->e_logo, $url, $self->logo_img, $self->logo_print, $self->site_menu
#  );
  return sprintf( '%s<a href="http://www.pombase.org">%s</a>%s%s',
    $self->e_logo, $self->logo_img, $self->logo_print, $self->site_menu
  );
}

sub e_logo {
### a
  my $self = shift;
  my $alt = 'Ensembl Genomes Home';
  return q{};
  #return sprintf(
  #  '<a href="%s"><img src="%s%s" alt="%s" title="%s" class="print_hide" style="width:%spx;height:%spx" /></a>',
  #  'http://www.ensemblgenomes.org/', $self->img_url, 'e.png', $alt, $alt, 43, 40
  #);
}

sub site_menu {
  return q{
    <span class="print_hide">
      <span id="site_menu_button">&#9660;</span>
      <ul id="site_menu" style="display:none">
        <li><a href="http://fungi.ensembl.org">Ensembl Fungi</a></li>
      </ul>
    </span>
  };
}

1;
