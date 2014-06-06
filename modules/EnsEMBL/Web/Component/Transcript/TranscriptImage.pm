package EnsEMBL::Web::Component::Transcript::TranscriptImage;

use strict;
use Data::Dumper;
use base qw(EnsEMBL::Web::Component::Transcript);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self         = shift;
  my $object       = $self->object;
  my $transcript   = $object->Obj;
  my $slice        = $transcript->feature_Slice;
     $slice        = $slice->invert if $slice->strand < 1; ## Put back onto correct strand
  my $image_config = $object->get_imageconfig('single_transcript');
  my $hub = $self->hub;
  
  $image_config->set_parameters({
    container_width => $slice->length,
    image_width     => $hub->param('i_width') || 700,
    slice_number    => '1|1',
  });

  ## Now we need to turn on the transcript we wish to draw

  #warn (Dumper($object));
  my $key  = $image_config->get_track_key('transcript', $object);
  #warn (Dumper($key));
  my $node = $image_config->get_node($key) || $image_config->get_node(lc $key);
  #warn (Dumper($node));
  $node->set('display', 'transcript_label') if $node->get('display') eq 'off';
  $node->set('show_labels', 'off');

  ## Show the ruler only on the same strand as the transcript
  $image_config->modify_configs(
    [ 'ruler' ],
    { 'strand', $transcript->strand > 0 ? 'f' : 'r' }
  );

  $image_config->set_parameter('single_Transcript' => $transcript->stable_id);
  $image_config->set_parameter('single_Gene'       => $object->gene->stable_id) if $object->gene;

  $image_config->tree->dump('Tree', '[[caption]]') if $object->species_defs->ENSEMBL_DEBUG_FLAGS & $object->species_defs->ENSEMBL_DEBUG_TREE_DUMPS;

  my $image = $self->new_image($slice, $image_config, []);
  
  return if $self->_export_image($image);
  
  $image->imagemap         = 'yes';
  $image->{'panel_number'} = 'transcript';
  $image->set_button('drag', 'title' => 'Drag to select region');

  return $image->render;
}

1;

