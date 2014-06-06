package EnsEMBL::Web::Component::Transcript::Stats;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Transcript);
use EnsEMBL::Web::Document::HTML::TwoCol;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  1 );
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $tl = $object->Obj->translation;
  return '' unless $tl;
  return '<p>Pepstats currently disabled for Prediction Transcripts</p>' unless $tl->stable_id;
  my $db_type = ($object->db_type eq 'Ensembl') ? 'core' : lc($object->db_type); #thought there was a better way to do this!
  my $attributeAdaptor = $object->database($db_type)->get_AttributeAdaptor();
  my $attributes = $attributeAdaptor->fetch_all_by_Translation($tl);
  my $stats_to_show = '';
  #my @attributes_pepstats = grep {$_->description =~ /Pepstats/} @{$attributes};
  foreach my $stat (sort {$a->name cmp $b->name} @{$attributes}) {
      $stats_to_show .= sprintf("%s: %s<br />",$stat->name,$object->thousandify($stat->value));
  }
  my $table  = new EnsEMBL::Web::Document::HTML::TwoCol;
  unless ($stats_to_show =~/^\w/){return;}
  $table->add_row('Statistics',
		  "<p>$stats_to_show</p>",
		  1 );
  return $table->render;
  #return $tl;
}

1;
