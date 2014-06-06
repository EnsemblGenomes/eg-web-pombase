# $Id: Summary.pm,v 1.1.1.1 2013-02-15 16:11:31 ek3 Exp $

package EnsEMBL::Web::Document::Element::Summary;

# Generates the top summary panel in dynamic pages

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub init {
  my $self       = shift;
  my $controller = shift;
  my $hub        = $self->hub;
  my $object     = $controller->object;
  my $caption    = $object ? $object->caption : $controller->configuration->caption;
  my $component  = sprintf 'EnsEMBL::Web::Component::%s::%s', $hub->type, $hub->action eq 'Multi' ? 'MultiIdeogram' : 'Summary';

  return unless $self->dynamic_use($component);  
  return if (($hub->action =~ /Genome/) || ($hub->action =~ /Chromosome/) || ($hub->action =~ /(Multi)?Synteny/));

  my $panel = $self->new_panel('Summary',
    $controller,
    code    => 'summary_panel',
    caption => $caption
  );
  
  $panel->add_component('summary', $component);
  $controller->page->content->add_panel($panel);
}

1;
