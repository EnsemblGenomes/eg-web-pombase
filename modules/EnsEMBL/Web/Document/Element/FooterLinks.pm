package EnsEMBL::Web::Document::Element::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;

sub content {

  return qq(
    <div class="twocol-right right unpadded">
      <a href="http://www.ensemblgenomes.org">About EnsemblGenomes</a> | 
      <a href="http://legacy.pombase.org/feedback">Contact PomBase</a> | 
      <a href="/info/about/contact/index.html">Contact Ensembl</a> | 
      <a href="/info/website/help/index.html">Ensembl Help</a> 
    </div>) 
  ;
}

1;

